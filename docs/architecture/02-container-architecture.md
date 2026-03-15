# Container Architecture

Status: Accepted
Date: 2026-03-15

## Context

To support scalability and independent evolution of system capabilities, the platform is decomposed into containerized services.

Each service is responsible for a clearly bounded domain.

## Container Diagram

```mermaid
flowchart TB
    subgraph Clients
        C1[Chat UI]
        C2[Internal Apps]
        C3[GitHub Webhooks]
        C4[Operator Console]
    end

    subgraph Gateway
        G1[Ingress API]
        G2[SLM Classifier]
        G3[Policy Scan]
        G4[Budget Router]
        G5[Semantic Cache]
        G6[Escalation Judge]
    end

    subgraph Mesh
        M1[Specialist Router]
        M2[Task Decomposer]
        M3[State Manager]
        M4[Synthesis Coordinator]
    end

    subgraph Forge
        F1[Tool Selector]
        F2[Argument Extractor]
        F3[Execution Loop]
        F4[Result Compressor]
    end

    subgraph CodeFlow
        CF1[PR Classifier]
        CF2[Risk Scorer]
        CF3[CI Triage]
        CF4[Review Engine]
    end

    subgraph Models
        SLM[SLM Pool]
        LLM[LLM Pool]
    end

    C1 --> G1
    C2 --> G1
    C4 --> G1

    G1 --> G2
    G2 --> G3
    G3 --> G4
    G4 --> G5
    G5 --> G6

    G6 --> M1
    G6 --> F1
    G6 --> CF1

    M1 --> M2
    M2 --> M3
    M3 --> M4

    F1 --> F2
    F2 --> F3
    F3 --> F4

    CF1 --> CF2
    CF2 --> CF3
    CF3 --> CF4
```

## Consequences

### Benefits

- service isolation
- independent scaling
- clearer ownership

### Tradeoffs

- increased service orchestration complexity
