# Practical Deployment Model

This is the recommended stack for the ecosystem.

## Full Stack Architecture

```mermaid
flowchart TD
    A[Ingress] --> B[AI Gateway SLM]
    B --> C1[Fast-path]
    B --> C2[Tool-first]
    B --> C3[Escalation]
    C2 --> D1[AgentKit]
    C2 --> D2[CodeFlow]
    C2 --> D3[Cognitive Mesh]
    D1 --> E1[SLM tool loops]
    D2 --> E2[SLM CI triage]
    D3 --> E3[SLM orchestration]
    E1 --> F[LLM Pool]
    E2 --> F
    E3 --> F
    G[Rooivalk Edge] --> H[Local SLM]
    H --> I[Local / Cloud]
    F --> J[Observability]
```

## Decision Matrix

| System          | Best SLM Jobs              | Less Suitable                  |
| --------------- | -------------------------- | ------------------------------ |
| AI Gateway      | routing, screening, cost   | Nuanced synthesis              |
| Cognitive Mesh  | routing, decomposition     | Final judgment                 |
| CodeFlow        | PR triage, log analysis    | Root cause across dependencies |
| AgentKit        | tool selection, extraction | Multi-step planning            |
| PhoenixRooivalk | summaries, alerts          | Sole threat authority          |
| Mystira         | safety, continuity         | Rich narrative                 |

## Practical Gateway Flow

```mermaid
flowchart LR
    A[Request] --> B[Classifier]
    B --> C[Policy Scan]
    C --> D[Budget Rules]
    D --> E{Decision}
    E -->|simple| F[Small Model]
    E -->|tool| G[Tools]
    E -->|complex| H[LLM]
    E -->|blocked| I[Refusal]
    G --> J[Post-tool Summarizer]
    J --> H
```

## End-to-End Example

A developer opens a PR that changes Terraform, GitHub Actions, and an OpenAPI spec:

```mermaid
sequenceDiagram
    Dev->>GH: Open PR
    GH->>CF: Event
    CF->>SLM: Classify + risk
    SLM-->>CF: infra-change, high risk
    CF->>GH: Full CI + contract checks
    GH-->>CF: Results
    CF->>SLM: Triage logs
    SLM-->>CF: Breaking change detected
    CF->>AG: Escalate
    AG->>LLM: Reasoning
    LLM-->>AG: Advice
    AG-->>CF: Response
    CF-->>GH: Comment
```

SLMs handle repetitive triage; LLMs solve the hard part.
