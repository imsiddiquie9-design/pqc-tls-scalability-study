#!/bin/sh

echo "=========================================================="
echo "Getting Container INDEX"
echo "=========================================================="

INDEX=$(curl -s --unix-socket /var/run/docker.sock \
  "http://v1.41/containers/$(hostname)/json" \
  | jq -r '.Config.Labels["com.docker.compose.container-number"]')

export CLIENT_NAME="pqc_client_$INDEX"

echo "This is $CLIENT_NAME"

SERVICE="pqc_client"
PROJECT="pqc_lastest"
 
container_id=$(hostname)
TOTAL_SCALE="$SCALE_SIZE"  
network_profile="$NETWORK_PROFILE"
num_handshakes="$NUM_OF_HANDSHAKES"

date_folder=$(date +%Y-%m-%d)

if [ "$IS_NETEM" = "true" ]; then
    base_dir="/results/with_netem"
else
    base_dir="/results/without_netem"
fi

output_dir="${base_dir}/${date_folder}/${network_profile}/total_client_${TOTAL_SCALE}/${CLIENT_NAME}/hs_${num_handshakes}"


if [ -d "$output_dir" ]; then
  echo "Folder already exists: $output_dir"
else
  echo "Creating folder: $output_dir"
  mkdir -p "$output_dir"
fi

export LAST_OUTPUT_DIR="$output_dir"
echo "Last Output Dir: $LAST_OUTPUT_DIR"

PROFILE_METADATA_FILE="${output_dir}/profile_summary_${CLIENT_NAME}_${num_handshakes}.json"

cat > "$PROFILE_METADATA_FILE" <<EOF
{
  "created_at": "$date_folder",

  "concurrency_info": {
    "total_clients": $TOTAL_SCALE,
    "repeats": $NUM_OF_EXPERIMENTS_REPEATS,
    "mode": "parallel"
  },

  "client_info": {
    "client_name": "$CLIENT_NAME",
    "container_id": "$container_id",
    "netem_enabled": $IS_NETEM,
    "output_dir": "$output_dir",
    "network_profile": "$NETWORK_PROFILE",
    "num_handshakes": $num_handshakes
  },

  "tls_parameters": {
    "tls_version": "TLS 1.3",
    "cipher_suite": "TLS_AES_256_GCM_SHA384",
    "kem_group": "$KEM_GROUP",
    "signature_algorithm": "rsa_pss_rsae_sha256",
    "server_public_key_type": "RSA-2048",
    "certificate_self_signed": true
  },

  "randomness_control": {
    "rng_mode": "static",
    "rtt_sampling_strategy": "sampled-once",
    "jitter_sampling_strategy": "sampled-once",
    "loss_sampling_strategy": "sampled-once"
  },

  "netem_parameters": {},
  "durations": {}
}
EOF


if [ "$IS_NETEM" = "true" ]; then
    echo "=========================================================="
    echo "Applying Netem on $CLIENT_NAME"
    echo "=========================================================="
    sh /workspace/netem.sh apply "$PROFILE_METADATA_FILE"
else
    echo "NetEm is DISABLED for $CLIENT_NAME"
fi

echo "=========================================================="
echo "🚀 Starting PQC TLS Client"
echo "=========================================================="

sh /workspace/build.sh "$NUM_OF_EXPERIMENTS_REPEATS" "$NUM_OF_HANDSHAKES" "$CLIENT_NAME" "$LAST_OUTPUT_DIR"
