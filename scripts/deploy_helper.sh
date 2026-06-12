#!/bin/bash

# --- Copied verbatim from ml-ops-kserve-iris ---
check_pods_ready() {
    local ns=$1
    local label=$2
    local component_name=$3

    TIMEOUT=$4  # Timeout per attempt
    RETRIES=$5  # Max retries
    COUNT=0

    # Record the start time
    START_TIME=$(date +%s)

    while [[ $COUNT -lt $RETRIES ]]; do

       if kubectl wait --for=condition=Ready pod -l "$label" -n "$ns" --timeout=$TIMEOUT 2>/dev/null; then
                  END_TIME=$(date +%s)
                  TOTAL_TIME=$((END_TIME - START_TIME))
                  print_info "✅ $component_name is ready! (Waited ${TOTAL_TIME}s)"
                  return 0
       fi
      COUNT=$((COUNT + 1))
      print_warning "⏳ Waiting for $component_name... Attempt $COUNT/$RETRIES"
      sleep 5
    done

    # If max retries reached, print failure message
    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    print_error "⚠️ $component_name did not become ready after ${TOTAL_TIME}s and $RETRIES attempts."

    return 1
}
# --- End verbatim copy ---

deploy_infra() {
  print_info "Adding Helm repos..."
  helm repo add kedacore https://kedacore.github.io/charts 2>/dev/null || true
  helm repo add vllm https://vllm-project.github.io/production-stack 2>/dev/null || true
  helm repo update

  print_info "Installing KEDA..."
  helm install keda kedacore/keda \
    --namespace keda \
    --create-namespace \
    --wait

  check_pods_ready "keda" "app=keda-operator" "keda-operator" "10s" "15"
  print_info "Infrastructure ready."
}

deploy_vllm() {
  print_info "Installing vLLM production stack..."
  helm install vllm-local vllm/vllm-stack \
    --namespace vllm \
    --create-namespace \
    -f helm/values-local.yaml \
    --wait \
    --timeout 15m

  check_pods_ready "vllm" \
    "app.kubernetes.io/component=serving-engine,helm-release-name=vllm-local" \
    "vllm-serving-engine" "30s" "30"

  print_info "Applying NodePort service and KEDA ScaledObject..."
  kubectl apply -f helm/nodeport-service.yaml
  kubectl apply -f helm/keda-scaledobject.yaml

  print_info "vLLM stack deployed."
}

remove_vllm() {
  print_info "Removing KEDA ScaledObject and NodePort service..."
  kubectl delete -f helm/keda-scaledobject.yaml --ignore-not-found=true 2>/dev/null || true
  kubectl delete -f helm/nodeport-service.yaml --ignore-not-found=true 2>/dev/null || true

  print_info "Uninstalling vLLM stack..."
  helm uninstall vllm-local --namespace vllm 2>/dev/null || true

  print_info "vLLM stack removed."
}
