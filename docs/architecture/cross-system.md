# Cross-System Architecture

These systems together form a layered architecture.

```
                User / Operator
                        │
                        ▼
                AI Gateway
                        │
                (SLM Routing Layer)
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
   Cognitive Mesh   CodeFlow Engine   AgentKit Forge
        │               │                │
        │               │                │
        └───────────────┼────────────────┘
                        │
                        ▼
                Large Model Layer
                        │
                        ▼
               PhoenixRooivalk Edge
                    (SLM Edge AI)
```

## Layer Responsibilities

### Layer 1: Edge (PhoenixRooivalk)

- Local inference only
- No cloud dependency
- Immediate threat response
- Minimal latency

### Layer 2: Gateway (AI Gateway)

- First request touchpoint
- Security policy enforcement
- Cost routing decisions
- Telemetry tagging

### Layer 3: Orchestration (Cognitive Mesh, AgentKit Forge)

- Multi-agent coordination
- Task decomposition
- Tool selection
- LLM escalation

### Layer 4: Intelligence (CodeFlow Engine)

- CI/CD automation
- Log analysis
- Commit classification
- Release management

### Layer 5: Large Model Layer

- Complex reasoning
- Creative generation
- Deep analysis
- Final synthesis

## Data Flow

```
Edge Event (Rooivalk)
    │
    ▼ Classify locally
Report
    │
    ▼ Route via Gateway
AI Gateway
    │
    ├─→ Route to Cognitive Mesh (agent task)
    ├─→ Route to CodeFlow (CI task)
    └─→ Route to AgentKit (tool task)
         │
         ▼
    SLM Selection
         │
    ┌────┼────┐
    │    │    │
    ▼    ▼    ▼
  Tool  LLM  Cache
         │
         ▼
    Result + Telemetry
         │
         ▼
    Cost Attribution
```

## Why SLMs Matter

Across all five platforms, SLMs provide:

| Benefit                | Description                             |
| ---------------------- | --------------------------------------- |
| Cost Control           | Large models invoked only when required |
| Latency Reduction      | Routing decisions in milliseconds       |
| Edge Deployment        | PhoenixRooivalk inference locally       |
| Deterministic Behavior | Easier to constrain and audit           |

## Summary

| System          | SLM Role                                |
| --------------- | --------------------------------------- |
| AI Gateway      | routing, policy checks, cost prediction |
| Cognitive Mesh  | agent routing, task decomposition       |
| PhoenixRooivalk | edge telemetry analysis                 |
| CodeFlow Engine | CI intelligence, log analysis           |
| AgentKit Forge  | tool selection, context compression     |
