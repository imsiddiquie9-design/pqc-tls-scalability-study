#!/bin/bash

# Auto-detect container ID and name
container_id=$(hostname)
num_handshakes="$NUM_OF_HANDSHAKES"
container_name="$CLIENT_NAME"
profile_output_dir="$LAST_OUTPUT_DIR"
TOTAL_SCALE="$SCALE_SIZE"
network_profile="$NETWORK_PROFILE"
num_experiment_repeats="$NUM_OF_EXPERIMENTS_REPEATS"



today_date=$(date +%Y-%m-%d)
timestamp=$(date +%H-%M-%S)
group="$KEM_GROUP"


global_start=$(date +%s%3N)


if [ -z "$num_handshakes" ]; then
    echo "Error: Please provide number of num_handshakes."
    echo "Usage: sh run_client.sh 1000"
    exit 1
fi



echo "=========================================================="
echo "Starting PQC TLS Container..."
echo "Container Name            : $container_name"
echo "No. of Handshakes         : $num_handshakes"
echo "Network Profile           : $network_profile"
echo "Profile Output Directory  : $profile_output_dir"
echo "Total Scale               : $TOTAL_SCALE"
echo "No. of Experiment Repeats : $num_experiment_repeats"
echo "=========================================================="


for repeat in $(seq 1 "$num_experiment_repeats"); do
    
    echo ""
    echo "=========================================================="
    echo "🔁 Experiment Repeat $repeat of $num_experiment_repeats"
    echo "=========================================================="


    output_dir="${profile_output_dir}/repeats_${repeat}/"

    mkdir -p "$output_dir"

    CSV_FILE="${output_dir}/${container_name}_handshakes_${num_handshakes}.csv"

    if [ ! -f "$CSV_FILE" ]; then
      echo "timestamp,container_name,run_id,hybrid_group,handshake_time_ms" > "$CSV_FILE"
    fi

    
    exp_start=$(date +%s%3N)

    # Run handshakes
    for i in $(seq 1 "$num_handshakes"); do
        start=$(date +%s%3N)
        openssl s_client -groups "$group" -connect pqc_server:443 \
            < /dev/null > /dev/null 2>&1
        end=$(date +%s%3N)

        diff=$((end - start))
        now=$(date +"%Y-%m-%d %H:%M:%S")

        echo "$now,$container_name,$i,$group,$diff" >> "$CSV_FILE"
    done

    exp_end=$(date +%s%3N)
    total_time=$((exp_end - exp_start))
    approx_secs=$(( total_time / 1000 ))
    summary_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    JSON_FILE="${output_dir}/meta_data_${container_name}_repeat${repeat}.json"

    cat > "$JSON_FILE" <<EOF
    {
      "experiment_date": "$today_date",
      "start_time": "$exp_start",
      "end_time": "$exp_end",
      "experiment_duration_in_ms": "$total_time",
      "experiment_duration_in_seconds": "$approx_secs"    
    }
EOF
    echo ""
    echo "=========================================================="
    echo "🔁 Total Time Taken By Client $repeat = $total_time ms or $approx_secs s"
    echo "=========================================================="


    echo ""
    echo "Repeat $repeat finished: ${total_time} ms (${approx_secs} sec)"

    echo "Sleeping 5 seconds before next repeat..."
    sleep 5
done

global_end=$(date +%s%3N)
global_total=$((global_end - global_start))
global_secs=$((global_total / 1000))



echo ""
echo "=========================================================="
echo "PQC TLS Client Finished!"
echo "Total Time Taken By Client (all num_handshakes and repeats): ${global_total} ms"
echo "Approx Seconds             : ${global_secs}"
echo "=========================================================="

PROFILE_JSON_FILE="${profile_output_dir}/profile_summary_${container_name}_${num_handshakes}.json"

jq \
  --arg date "$today_date" \
  --arg start "$global_start" \
  --arg end "$global_end" \
  --arg ms "$global_total" \
  --arg sec "$global_secs" \
  '
  .durations = {
      experiment_date: $date,
      start_time: ($start | tonumber),
      end_time: ($end | tonumber),
      experiment_duration_in_ms: ($ms | tonumber),
      experiment_duration_in_seconds: ($sec | tonumber)
  }
  ' "$PROFILE_JSON_FILE" > "${PROFILE_JSON_FILE}.tmp" && mv "${PROFILE_JSON_FILE}.tmp" "$PROFILE_JSON_FILE"


