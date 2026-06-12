# Brainstorm: Local vLLM Inference Stack on Kubernetes (Minikube)

> Created: 2026-06-12
> Status: Design Exploration (not yet a formal spec)

## Problem Statement

Deploy a fully functional vLLM inference stack on a local Kubernetes cluster using
Minikube on Apple Silicon (M5 MacBook Pro). The goal is not production performance —
it is to validate and learn the full vLLM-on-Kubernetes deployment architecture using
a CPU-only small model that will return real responses, proving the infrastructure is
correctly wired end-to-end.

**Target Users:** Developer building MLOps/AI infrastructure portfolio and learning
vLLM deployment patterns for production Kubernetes environments.
**Success Criteria:** vLLM running inside Minikube, serving a small quantised model
via an OpenAI-compatible `/v1/chat/completions` endpoint, reachable from the host
machine, returning valid (if slow) responses. Helm chart, manifests, and KEDA
autoscaling config all present and documented.

## Approaches Considered

### Approach A: Raw Kubernetes Manifests (Deployment + Service + ConfigMap)
Hand-write a `Deployment`, `Service`, `ConfigMap`, and `PersistentVolumeClaim`
for vLLM without Helm.
✅ Benefits: Full visibility into every resource; no Helm abstraction to debug
⚠️ Trade-offs: Verbose; diverges from how production vLLM deployments are managed;
harder to parameterise for future GPU swap

### Approach B: Official vLLM Helm Chart (`vllm-project/production-stack`)
Use the official vLLM Helm chart with a local `values-local.yaml` override file
that disables GPU, sets CPU/memory limits, and targets a small model.
✅ Benefits: Matches real production deployment pattern exactly; values override is
the only diff between local CPU and production GPU; Helm-native; well documented
⚠️ Trade-offs: Chart pulls in more resources than strictly needed for a local spike;
initial setup requires understanding chart structure

### Selected: Approach B
**Reasoning:** The learning objective is production-equivalent architecture, not a
minimal toy setup. Using the official Helm chart means the only change when moving
to a real GPU cluster is flipping `requestGPU: 0` to `requestGPU: 1` and swapping
the model repo. Everything else — service exposure, probes, autoscaling, ingress —
transfers directly.

## Design Overview

### Architecture

Single Minikube cluster with the vLLM production-stack Helm chart, a PVC for model
weight caching, and a NodePort service for host access.

```
minikube/
  values-local.yaml          ← CPU override; model selection; resource limits
  keda-scaledobject.yaml     ← KEDA autoscaling on request queue depth
  ingress.yaml               ← Optional: nginx ingress for /v1 routing
  smoke-test.sh              ← curl-based endpoint validation script
  README.md                  ← Setup steps and architecture notes
```

Model weights are downloaded once into a `PersistentVolumeClaim` on first startup and
reused on subsequent pod restarts — avoids re-downloading on every `helm upgrade`.

### Data Flow

```
Host machine (curl / Python client)
  → kubectl port-forward OR NodePort svc/vllm-local:8000
      → vLLM pod (Deployment, 1 replica)
          → loads Qwen2.5-0.5B-Instruct weights from PVC into CPU memory
          → runs inference (float32, CPU-only, slow but functional)
          → returns OpenAI-compatible JSON response
  → response received on host
```

KEDA `ScaledObject` watches the vLLM metrics endpoint for pending request queue
depth and scales replicas 1→N, demonstrating the autoscaling pattern even on CPU.

### Key Components

**`values-local.yaml`**
```yaml
servingEngineSpec:
  modelSpec:
  - name: "tiny-llm"
    repository: "Qwen/Qwen2.5-0.5B-Instruct"
    tag: "latest"
    replicaCount: 1
    requestCPU: 4
    requestMemory: "8Gi"
    requestGPU: 0
    pvcStorage: "10Gi"
    vllmConfig:
      dtype: "float32"        # float16 unsupported on CPU
      maxModelLen: 2048       # reduce KV cache pressure on CPU
      extraArgs:
        - "--enforce-eager"   # disables CUDA graph capture; required for CPU
        - "--disable-log-requests"
```

**`keda-scaledobject.yaml`**
- `ScaledObject` targeting the vLLM `Deployment`
- Trigger: vLLM Prometheus metrics — `vllm:num_requests_waiting` threshold
- Min replicas: 1, Max replicas: 3
- Demonstrates KEDA integration pattern; scaling won't be meaningful on CPU
  but the config is production-equivalent

**`ingress.yaml`**
- nginx `Ingress` resource routing `vllm.local/v1` → vLLM `Service`
- Requires `minikube addons enable ingress`
- Optional: NodePort service is sufficient for smoke testing

**`smoke-test.sh`**
```bash
#!/usr/bin/env bash
# Port-forward and send a single chat completion request
kubectl port-forward svc/vllm-local 8000:8000 &
sleep 2
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-0.5B-Instruct",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}],
    "max_tokens": 50
  }' | jq .
```

### Minikube Setup

```bash
# Start with sufficient resources for CPU inference
minikube start \
  --cpus=6 \
  --memory=12g \
  --disk-size=30g \
  --driver=docker

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server

# Install KEDA
helm repo add kedacore https://kedacore.github.io/charts
helm install keda kedacore/keda --namespace keda --create-namespace

# Install vLLM stack
helm repo add vllm https://vllm-project.github.io/production-stack
helm repo update
helm install vllm-local vllm/vllm-stack \
  --namespace vllm \
  --create-namespace \
  -f values-local.yaml
```

### Resource Layout

| Resource | Kind | Notes |
|---|---|---|
| `vllm-local` | Deployment | 1 replica; CPU-only; vLLM container |
| `vllm-local` | Service (NodePort) | Port 8000; OpenAI-compatible API |
| `vllm-model-pvc` | PersistentVolumeClaim | 10Gi; model weight cache |
| `vllm-config` | ConfigMap | Model name, dtype, extra args |
| `vllm-scaledobject` | ScaledObject (KEDA) | Queue-depth autoscaling |
| `vllm-ingress` | Ingress | nginx; routes `/v1` to service |

### Model Selection Rationale

**`Qwen/Qwen2.5-0.5B-Instruct`** chosen for:
- ~1GB weight footprint — fits comfortably in 8Gi memory limit
- Instruction-tuned — produces coherent responses even at this scale
- Supported natively by vLLM without custom config
- float32 CPU inference feasible within Minikube resource constraints

Alternative: `TinyLlama/TinyLlama-1.1B-Chat-v1.0` (~2.2GB float32) if a slightly
larger model is preferred. Not recommended to go larger than 1.1B on CPU in Minikube.

### Performance Expectations

| Metric | Expected value |
|---|---|
| First token latency | 30–120s (CPU inference) |
| Tokens per second | ~1–3 tok/s |
| Startup time (cold, no PVC) | 5–10 min (model download) |
| Startup time (warm, PVC hit) | 2–4 min |

These numbers are irrelevant to the learning objective. Any valid JSON response from
`/v1/chat/completions` constitutes a successful infrastructure proof.

### Error Handling

- Pod OOMKilled → reduce `maxModelLen` in `values-local.yaml` or switch to 0.5B model
- `float16` dtype error → confirm `dtype: "float32"` is set; CPU does not support float16
- CUDA graph capture error → confirm `--enforce-eager` is present in `extraArgs`
- Model download timeout → increase `initialDelaySeconds` on readiness probe;
  PVC will persist weights after first successful pull
- KEDA ScaledObject pending → confirm KEDA namespace and CRDs installed before
  applying ScaledObject manifest

### Testing Strategy

- `smoke-test.sh` — single curl request; validates endpoint reachability and JSON response
- `kubectl get pods -n vllm` — confirm pod Running and Ready
- `kubectl logs -n vllm deploy/vllm-local` — confirm model loaded, server listening
- `kubectl describe scaledobject vllm-scaledobject` — confirm KEDA trigger registered
- Manual load test: fire 3–5 concurrent requests; observe KEDA scaling event in logs

## Key Decisions

1. **Official Helm chart over raw manifests:** Production-equivalent deployment pattern
   from day one; local override is a single `values-local.yaml` file
2. **Qwen2.5-0.5B over TinyLlama:** Smaller footprint, better instruction following,
   lower risk of OOM on Minikube's constrained CPU memory
3. **float32 + enforce-eager:** Required for CPU-only inference; documented explicitly
   so the GPU upgrade path (remove both flags) is obvious
4. **PVC for model weights:** Avoids re-downloading multi-GB weights on every pod
   restart; mirrors production pattern of pre-cached model storage
5. **KEDA included despite CPU:** Autoscaling config is architecture learning, not
   performance — the ScaledObject pattern is identical on GPU clusters
6. **NodePort + port-forward over LoadBalancer:** Minikube has no external load balancer;
   NodePort is the correct local equivalent; ingress addon bridges to nginx for `/v1` routing
