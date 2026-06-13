#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/scripts/output_helper.sh"
source "${SCRIPT_DIR}/scripts/minikube_manager.sh"
source "${SCRIPT_DIR}/scripts/deploy_helper.sh"
source "${SCRIPT_DIR}/scripts/test_helper.sh"

usage() {
  print_error "Usage: $0 {start|deploy_infra|deploy_vllm|remove_vllm|test|stop|reset}"
  print_error ""
  print_error "Commands:"
  print_error "  start         Start Minikube with required resources and enable addons"
  print_error "  deploy_infra  Install KEDA and add Helm repos"
  print_error "  deploy_vllm   Deploy vLLM stack via Helm and apply KEDA ScaledObject"
  print_error "  remove_vllm   Uninstall vLLM stack and remove KEDA ScaledObject"
  print_error "  test          Send a smoke-test request to /v1/chat/completions"
  print_error "  stop          Stop Minikube"
  print_error "  reset         Delete cluster, rebuild from scratch, and redeploy everything"
  exit 1
}

if [ -z "${1:-}" ]; then
  usage
fi

case "$1" in
  start)
    start_time=$(date +%s)
    print_header "Starting Cluster"
    minikube_manager start
    print_info "Enabling Minikube addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    end_time=$(date +%s)
    print_info "Cluster ready in $((end_time - start_time))s"
    ;;
  deploy_infra)
    start_time=$(date +%s)
    print_header "Deploying Infrastructure"
    deploy_infra
    end_time=$(date +%s)
    print_info "Infrastructure deployed in $((end_time - start_time))s"
    ;;
  deploy_vllm)
    start_time=$(date +%s)
    print_header "Deploying vLLM Stack"
    deploy_vllm
    end_time=$(date +%s)
    print_info "vLLM stack deployed in $((end_time - start_time))s"
    ;;
  remove_vllm)
    print_header "Removing vLLM Stack"
    remove_vllm
    ;;
  test)
    print_header "Running Smoke Test"
    run_vllm_test
    ;;
  stop)
    print_header "Stopping Cluster"
    minikube_manager stop
    ;;
  reset)
    start_time=$(date +%s)
    print_header "Resetting Cluster"
    minikube_manager reset
    print_info "Enabling Minikube addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    deploy_infra
    deploy_vllm
    end_time=$(date +%s)
    print_info "Cluster reset and redeployed in $((end_time - start_time))s"
    ;;
  *)
    usage
    ;;
esac
