# Cross-System Architecture

These systems together form a layered architecture.

## Combined Architecture

```
                User / Operator
                        │
                        ▼
                AI Gateway
                        │
                (SLM Routing Layer)
                  intent, risk,
                  complexity, tools
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
   Cognitive Mesh   CodeFlow Engine   AgentKit Forge
        │               │                │
   (agent routing)  (CI triage)     (tool selection)
        │               │                │
        └───────────────┼────────────────┘
                        │
                        ▼
                Large Model Layer
              (reasoning, synthesis)
                        │
                        ▼
               PhoenixRooivalk Edge
                    (SLM Only)
              operator summaries,
              reports (NOT control)
```

## Layer Responsibilities

| Layer         | Primary                        | SLM Role          | LLM Role             |
| ------------- | ------------------------------ | ----------------- | -------------------- |
| Edge          | PhoenixRooivalk                | Reports only      | None                 |
| Gateway       | AI Gateway                     | Routing, security | Complex reasoning    |
| Orchestration | Cognitive Mesh, AgentKit Forge | Routing, tools    | Synthesis            |
| Intelligence  | CodeFlow Engine                | Triage            | None                 |
| Synthesis     | LLM Layer                      | None              | Reasoning, synthesis |

## SLM Role by Platform

| Platform        | Best SLM Role                             | Should SLM be Primary? | Escalate to LLM When              |
| --------------- | ----------------------------------------- | ---------------------- | --------------------------------- |
| AI Gateway      | routing, safety, cost control             | **yes**                | ambiguity, complex reasoning      |
| Cognitive Mesh  | agent routing, decomposition, compression | **yes**                | cross-agent synthesis needed      |
| CodeFlow Engine | PR/CI triage, failure summaries           | **yes**                | root cause requires deep analysis |
| AgentKit Forge  | tool selection, memory shaping            | **yes**                | planning becomes ambiguous        |
| PhoenixRooivalk | operator summaries, reports               | **no**                 | strategic analysis or long-form   |

## Data Flow

```
Edge Event (Rooivalk)
    │
    ▼ Classify locally (rules + signal ML)
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

## Practical Deployment Pattern

### Tiered Model Strategy

| Tier   | Use For               | Examples                                                   |
| ------ | --------------------- | ---------------------------------------------------------- |
| Tier 0 | deterministic/non-LLM | regex, schemas, policies, hard routing                     |
| Tier 1 | SLM                   | classification, decomposition, compression, tool selection |
| Tier 2 | LLM                   | synthesis, complex reasoning, ambiguous requests           |

### Operating Pattern

```
Tier 0 (Rules)
    │
    ├─→ Direct pass/fail
    │
    ▼ (pass)
Tier 1 (SLM)
    │
    ├─→ Classification/compression
    │
    ▼ (needs more)
Tier 2 (LLM)
    │
    ├─→ Reasoning/synthesis
    │
    ▼
Response + Telemetry
```

## Implementation Order

1. **AI Gateway SLM router** — Highest immediate cost-leverage
2. **CodeFlow Engine CI/PR classifier** — Fastest operational value
3. **Cognitive Mesh decomposer/router** — Strong leverage once taxonomy stabilizes
4. **AgentKit Forge tool selector** — Useful once tool inventory is mature
5. **PhoenixRooivalk operator interpreter** — Valuable, keep isolated from critical control

## Summary

| System          | SLM Role                                    |
| --------------- | ------------------------------------------- |
| AI Gateway      | routing, policy checks, cost prediction     |
| Cognitive Mesh  | agent routing, task decomposition           |
| PhoenixRooivalk | edge telemetry interpretation (NOT control) |
| CodeFlow Engine | CI intelligence, log analysis               |
| AgentKit Forge  | tool selection, context compression         |

## Key Principles

1. **SLMs decide, LLMs reason** — SLM for routing/classification, LLM for synthesis
2. **Schema-bound outputs** — Always use structured output schemas
3. **Confidence cascades** — Low confidence → escalate to next tier
4. **Safety boundaries** — Never use SLM for safety-critical decisions (Rooivalk)
5. **Cost controls** — Budget caps, monitoring, alerts
