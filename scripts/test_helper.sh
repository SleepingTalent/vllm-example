#!/bin/bash

run_vllm_test() {
  print_info "Starting port-forward to vllm-nodeport..."
  LOCAL_PORT=18000
  kubectl port-forward svc/vllm-nodeport ${LOCAL_PORT}:8000 -n vllm &>/dev/null &
  PF_PID=$!
  sleep 3  # give port-forward time to establish

  print_info "Sending chat completion request..."
  curl -s "http://localhost:${LOCAL_PORT}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "Qwen/Qwen2.5-0.5B-Instruct",
      "messages": [{"role": "user", "content": "Say hello in one sentence."}],
      "max_tokens": 50
    }' | jq .

  kill $PF_PID 2>/dev/null || true
  print_info "Smoke test complete."
}
