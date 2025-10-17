#!/bin/bash

namespace="agents"
TIMEOUT=300     # 5 minutes timeout
INTERVAL=5      # Check every 5 seconds
LOG_INTERVAL=30 # Log only every 30 seconds
start_time=$(date +%s)
last_log_time=${start_time}

get_pod_names() {
  kubectl get pods -n "$namespace" -o custom-columns=":metadata.name"
}

check_pod_status() {
  all_running=true
  pods=($(get_pod_names))

  if [[ ${#pods[@]} -eq 0 ]]; then
    echo "ERROR: No pods found in the namespace '$namespace'."
    all_running=false
  fi

  for pod in "${pods[@]}"; do
    pod_status=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.status.phase}')

    if [[ "$pod_status" != "Running" ]] && [[ "$pod_status" != "Succeeded" ]]; then
      echo "Pod $pod is not in Running state yet. Current status: $pod_status"
      all_running=false
      break
    fi
  done

  if [[ ${all_running} == true ]]; then
    return 0
  else
    return 1
  fi
}

while true; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if [[ ${elapsed} -ge ${TIMEOUT} ]]; then
    echo "ERROR: Timeout reached after ${TIMEOUT} seconds"
    exit 1
  fi

  if check_pod_status; then
    echo "All pods are in Running state."
    sleep 10
    exit 0
  else
    # Only log every LOG_INTERVAL seconds
    time_since_last_log=$((current_time - last_log_time))
    if [[ ${time_since_last_log} -ge ${LOG_INTERVAL} ]]; then
      remaining=$((TIMEOUT - elapsed))
      echo "Waiting for all pods to reach Running state... (${remaining}s remaining)"
      last_log_time=${current_time}
    fi
  fi

  sleep ${INTERVAL}
done