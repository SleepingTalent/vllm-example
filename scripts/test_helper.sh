#!/bin/bash

run_vllm_test() {
  print_info "Retrieving vLLM router service URL..."
  VLLM_URL=$(minikube service vllm-nodeport -n vllm --url)
  print_info "vLLM endpoint: ${VLLM_URL}"

  print_info "Sending chat completion request..."
  curl -s "${VLLM_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "Qwen/Qwen2.5-0.5B-Instruct",
      "messages": [{"role": "user", "content": "Say hello in one sentence."}],
      "max_tokens": 50
    }' | jq .

  print_info "Smoke test complete."
}
