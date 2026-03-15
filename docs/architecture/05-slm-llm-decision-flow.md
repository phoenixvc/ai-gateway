# SLM to LLM Decision Flow

Status: Accepted

## Context

Small Language Models are used as the operational cognition layer, while Large Language Models perform high-value reasoning.

## Decision Flow

```mermaid
flowchart TD
    A[Incoming Request]
    B[SLM Preprocess]
    C[Intent Classification]
    D[Policy Scan]
    E[Tool Check]
    F[Complexity Estimate]
    G[Confidence Score]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G

    G --> H{Policy violation?}
    H -->|Yes| X[Block / Redact]
    H -->|No| I{Simple task?}

    I -->|Yes| Y[Return SLM result]
    I -->|No| J{Tool first?}

    J -->|Yes| K[Execute Tool]
    K --> L[SLM Compress Result]
    L --> M{Enough?}

    M -->|Yes| Y
    M -->|No| N[Escalate]

    J -->|No| N

    N --> O[LLM Reasoning]
    O --> P[Post-check]
    P --> Q[Return Response]
```

## Consequences

### Benefits

- reduced inference cost
- lower latency
- improved throughput

### Risks

- incorrect routing
- model confidence calibration required
