#!/bin/sh
set -e

action="$1"
profile="$NETWORK_PROFILE"
json_file="$2"

DEVICE=$(ip -o link show | awk -F': ' '!/lo/ {print $2; exit}' | cut -d'@' -f1)
echo "=========================================================="
echo "Getting Container INDEX"
echo "=========================================================="

INDEX=$(curl -s --unix-socket /var/run/docker.sock \
  "http://v1.41/containers/$(hostname)/json" \
  | jq -r '.Config.Labels["com.docker.compose.container-number"]')

if [ -z "$INDEX" ] || [ "$INDEX" = "null" ]; then
  echo "ERROR: Could not determine container index"
  exit 1
fi

export CLIENT_INDEX="$INDEX"
export CLIENT_NAME="pqc_client_$CLIENT_INDEX"

echo "This is $CLIENT_NAME (INDEX=$CLIENT_INDEX)"

# ----------------------------------------------------------
# Seed handling 
# ----------------------------------------------------------

BASE_SEED=${NETEM_BASE_SEED:-42}
EFFECTIVE_SEED=$((BASE_SEED + CLIENT_INDEX))

export NETEM_SEED="$EFFECTIVE_SEED"

echo "Base Seed      : $BASE_SEED"
echo "Effective Seed : $NETEM_SEED"

# ----------------------------------------------------------
# Utility functions
# ----------------------------------------------------------
rand_float() {
    min=$1
    max=$2
    seed=$3

    awk -v min="$min" -v max="$max" -v seed="$seed" '
      BEGIN {
        srand(seed);
        print min + rand() * (max - min);
      }'
}

rand_truncated_normal_from_range() {
    min=$1
    max=$2
    seed=$3

    awk -v min="$min" -v max="$max" -v seed="$seed" '
    BEGIN {
        mean = (min + max) / 2;
        std  = (max - min) / 6;

        srand(seed);

        while (1) {
            u1 = rand();
            if (u1 <= 0) continue;
            u2 = rand();

            z = sqrt(-2 * log(u1)) * cos(2 * 3.141592653589793 * u2);
            x = mean + std * z;

            if (x >= min && x <= max) {
                printf "%.3f\n", x;
                break;
            }
        }
    }'
}


rand_gamma_from_range_python() {
    min=$1
    max=$2
    seed=$3

    python3 - <<EOF
import random

random.seed($seed)

# mean at middle of range
mean = ($min + $max) / 2

# choose shape (k)
k = 2.0

# scale so that mean = k * theta
theta = mean / k

x = random.gammavariate(k, theta)

# clamp to range
x = max($min, min($max, x))

print(round(x, 6))
EOF
}


# ===========================
# Profile selection
# ===========================

SEED=${NETEM_SEED:-42}

case "$profile" in
  "LAN")
      RTT=$(rand_truncated_normal_from_range 5 10 "$SEED")
      JITTER=$(rand_gamma_from_range_python 0 1 "$SEED")
      LOSS=0
      ;;
  "REGIONAL")
      RTT=$(rand_truncated_normal_from_range 30 40 "$SEED")
      JITTER=$(rand_gamma_from_range_python 1 5 "$SEED")
      LOSS=$(rand_float 0 0.5 "$SEED")
      ;;
  "CONTINENTAL")
      RTT=$(rand_truncated_normal_from_range 70 90 "$SEED")
      JITTER=$(rand_gamma_from_range_python 2 10 "$SEED")
      LOSS=$(rand_float 0 1 "$SEED")
      ;;
  "GLOBAL")
      RTT=$(rand_truncated_normal_from_range 180 220 "$SEED")
      JITTER=$(rand_gamma_from_range_python 5 20 "$SEED")
      LOSS=$(rand_float 0 1 "$SEED")
      ;;
  *)
      echo "Unknown NETWORK_PROFILE: $profile"
      exit 1
      ;;
esac



# ===========================
# Apply NETEM
# ===========================
if [ "$action" = "apply" ]; then

    tc qdisc del dev "$DEVICE" root 2>/dev/null || true

    echo "[+] Applying NetEm Profile: $profile"
    echo "    RTT: $RTT ms"
    echo "    Jitter: $JITTER ms"
    echo "    Loss: $LOSS %"
    echo "    Seed: $SEED"

    tc qdisc add dev "$DEVICE" root netem delay "${RTT}ms" "${JITTER}ms" loss "${LOSS}%"

    # Update JSON
    jq \
      --arg rtt "$RTT" \
      --arg loss "$LOSS" \
      --arg jitter "$JITTER" \
      --arg seed "$SEED" \
      '
      .netem_parameters.rtt_ms = ($rtt | tonumber) |
      .netem_parameters.loss_pct = ($loss | tonumber) |
      .netem_parameters.jitter_ms = ($jitter | tonumber) |
      .netem_parameters.seed_used = ($seed | tonumber)
      ' "$json_file" > "${json_file}.tmp" && mv "${json_file}.tmp" "$json_file"

    exit 0
fi

# ===========================
# Remove NETEM
# ===========================
if [ "$action" = "remove" ]; then
    tc qdisc del dev "$DEVICE" root 2>/dev/null || true
    echo "[+] Removed NetEm from $DEVICE"
    exit 0
fi
