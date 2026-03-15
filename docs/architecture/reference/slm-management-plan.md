# SLM Management Plan

This document outlines the key concerns and management strategy for SLM deployment across all projects.

## Key Concerns Overview

| Concern              | Priority | Projects Affected       |
| -------------------- | -------- | ----------------------- |
| Model Selection      | High     | All                     |
| Cost Management      | High     | All                     |
| Latency Requirements | High     | Gateway, Rooivalk       |
| Edge Deployment      | High     | Rooivalk                |
| Security & Privacy   | High     | Gateway, Cognitive Mesh |
| Reliability          | Medium   | All                     |
| Observability        | Medium   | All                     |
| Versioning           | Medium   | All                     |

## 1. Model Selection

### Strategy

Maintain a tiered model portfolio:

| Tier        | Models               | Use Cases                      | Cost            |
| ----------- | -------------------- | ------------------------------ | --------------- |
| Ultra-light | Phi-3 Mini, Gemma 2B | Classification, routing        | $0.0001/request |
| Light       | Phi-3, Llama 3 8B    | Tool selection, log analysis   | $0.001/request  |
| Medium      | Llama 3 70B          | Complex routing, decomposition | $0.01/request   |
| Heavy       | GPT-4 class          | Reasoning, synthesis           | $0.05+/request  |

### Management

- **Central model registry** with capability matrix
- **A/B testing framework** for model comparisons
- **Performance benchmarks** per use case category

## 2. Cost Management

### Strategy

Implement cost controls at each layer:

```
Cost Control Layers
┌─────────────────────────────────────┐
│ 1. Budget caps per project          │
├─────────────────────────────────────┤
│ 2. SLM-first routing (80%+ target) │
├─────────────────────────────────────┤
│ 3. Confidence-based escalation      │
├─────────────────────────────────────┤
│ 4. Request caching                 │
├─────────────────────────────────────┤
│ 5. Telemetry & alerting            │
└─────────────────────────────────────┘
```

### Targets

| Metric               | Target |
| -------------------- | ------ |
| SLM routing %        | >80%   |
| Cost per 1K requests | <$5    |
| LLM escalation rate  | <20%   |
| Cache hit rate       | >30%   |

### Alerts

- Cost spike >20% day-over-day
- LLM escalation >25%
- Budget utilization >80%

## 3. Latency Requirements

### Targets by Project

| Project         | Target P99 | Critical Path         |
| --------------- | ---------- | --------------------- |
| AI Gateway      | <100ms     | routing decision      |
| PhoenixRooivalk | <50ms      | threat classification |
| CodeFlow        | <2s        | PR classification     |
| Cognitive Mesh  | <500ms     | agent selection       |
| AgentKit Forge  | <1s        | tool selection        |

### Optimization

- **Model quantization** for edge (int4)
- **Caching** of frequent decisions
- **Batch processing** for non-critical tasks
- **Connection pooling** to inference endpoints

## 4. Edge Deployment (PhoenixRooivalk)

### Critical: SLM is NOT Primary

> **Never use SLM for safety-critical decisions.**

SLM is only for:

- Operator-facing summaries
- Report generation
- Post-mission narratives

Core detection uses:

- Rules + signal models + fusion engine

### Strategy

| Requirement        | Solution                        |
| ------------------ | ------------------------------- |
| Hardware diversity | Support Jetson, CPU, mobile     |
| Offline operation  | Full local inference capability |
| Model updates      | OTA with rollback               |
| Security           | No external connectivity        |

### Model Optimization

```python
# Standard edge optimization pipeline
optimizations = [
    quantization(weights="int4"),
    pruning(structured=0.3),
    distillation(student=phi3_mini),
    compilation(target="cuda|cpu")
]
```

## 5. Security & Privacy

### Strategy

| Layer      | Controls                                  |
| ---------- | ----------------------------------------- |
| Input      | Prompt injection detection, PII filtering |
| Processing | No data leaves boundary                   |
| Output     | Content filtering, audit logging          |
| Access     | Role-based model access                   |

### SLM Security Checks

```python
async def security_pipeline(request: Request) -> SecurityResult:
    # 1. Prompt injection check
    injection = await slm_check_injection(request.prompt)
    if injection.detected:
        return blocked(injection.reason)

    # 2. PII detection
    pii = await slm_check_pii(request.prompt)
    if pii.found:
        return blocked("PII detected")

    # 3. Policy check
    policy = await slm_check_policy(request.prompt)
    if policy.violation:
        return blocked(policy.violation)

    return allowed()
```

## 6. Reliability

### Strategy

| Concern             | Mitigation               |
| ------------------- | ------------------------ |
| Model downtime      | Fallback models per tier |
| Latency spikes      | Timeout + escalation     |
| Quality degradation | Continuous evaluation    |
| Hallucinations      | Confidence thresholds    |

### Fallback Hierarchy

```
Request
   │
   ▼ Primary SLM
   │
   ├─ Success → Return
   │
   ├─ Timeout → Fallback SLM
   │
   ├─ Low confidence → LLM verification
   │
   └─ Failure → Error with telemetry
```

## 7. Observability

### Metrics Collection

| Metric Type    | Collection                 |
| -------------- | -------------------------- |
| Request volume | Per model, per project     |
| Latency        | P50, P95, P99 per endpoint |
| Error rate     | By error type, model       |
| Cost           | Per project, per user      |
| Quality        | Accuracy, escalation rate  |

### Dashboards

- **Cost Dashboard**: Spend by project, model, day
- **Performance Dashboard**: Latency by tier
- **Quality Dashboard**: Accuracy, false positives

## 8. Versioning

### Strategy

| Component      | Versioning       | Update Frequency   |
| -------------- | ---------------- | ------------------ |
| Models         | Semantic (1.0.0) | Monthly evaluation |
| Prompts        | Git-based        | Per task           |
| Infrastructure | Terraform        | Per deployment     |

### Model Lifecycle

```
Discovery → Testing → Staging → Production → Deprecated → Retired
    │           │         │          │            │
    ▼           ▼         ▼          ▼            ▼
 Evaluate   A/B test   Shadow mode  Active      Fallback
```

## Project-Specific Concerns

### AI Gateway

- High-volume routing
- Security-first evaluation
- Real-time cost tracking

### Cognitive Mesh

- Agent capability mapping
- Task decomposition accuracy
- Multi-agent coordination

### PhoenixRooivalk

- **CRITICAL**: SLM NOT for safety decisions
- Edge hardware diversity
- Offline reliability
- Minimal latency

### CodeFlow Engine

- PR classification accuracy
- CI log analysis quality
- Auto-merge reliability

### AgentKit Forge

- Tool selection accuracy
- Context compression ratio
- LLM call reduction

## Canonical Principle

> **Use SLMs to decide, filter, classify, compress, and prepare.**
> **Use LLMs to reason, reconcile, synthesize, and communicate.**

## Action Items

1. [ ] Establish model registry with tiered selection
2. [ ] Implement cost tracking per project
3. [ ] Set up latency monitoring dashboards
4. [ ] Create edge deployment pipeline
5. [ ] Build security check pipeline
6. [ ] Define fallback hierarchies
7. [ ] Implement observability stack
8. [ ] Document model lifecycle process
9. [ ] **Add explicit safety boundary for PhoenixRooivalk**
