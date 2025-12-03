#!/bin/bash

NAMESPACE="agents"
CONFIGMAP="discovery-engine-sumengine"
DEPLOYMENT="discovery-engine"
NEW_INTERVAL="0h0m05s"

# Patch the ConfigMap with the new interval
kubectl get configmap $CONFIGMAP -n $NAMESPACE -o yaml | \
    sed "s/cron-interval: 0h05m0s/cron-interval: $NEW_INTERVAL/g" | \
    kubectl apply -f -

echo "Restarting deployment $DEPLOYMENT..."
kubectl rollout restart deployment $DEPLOYMENT -n $NAMESPACE

# Wait for the pod to restart
kubectl wait --for=condition=available --timeout=60s deployment/$DEPLOYMENT -n $NAMESPACE

# Verify the change
updated_interval=$(kubectl get configmap $CONFIGMAP -n $NAMESPACE -o yaml | grep cron-interval)
echo "Updated interval: $updated_interval"

