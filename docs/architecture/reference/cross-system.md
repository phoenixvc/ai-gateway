# Cross-System Architecture

This document describes the unified production architecture that separates:

- Control plane vs execution plane
- SLM tier vs LLM tier
- Cloud vs edge
- Policy, observability, cache, and cost controls

## Unified Production Architecture

```mermaid
flowchart TB
    subgraph Clients["Ingress Sources"]
        U1[Users]
        U2[Developers / PR Events]
        U3[Apps / APIs]
        U4[Operators / Mission Console]
        U5[Sensors / Telemetry]
    end

    subgraph Cloud["Cloud Control Plane"]
        GW[AI Gateway]

        subgraph SLMCP["SLM Control Tier"]
            S1[Intent + Complexity Classifier]
            S2[Policy / PII / Secret / Injection Scan]
            S3[Cost + Latency Router]
            S4[Semantic Cache Admission / Reuse]
            S5[Context Compressor]
            S6[Escalation Judge]
        end

        subgraph Orchestration["Orchestration Services"]
            CM[Cognitive Mesh]
            AF[AgentKit Forge]
            CF[CodeFlow Engine]
        end

        subgraph SharedServices["Shared Platform Services"]
            POL[Policy Engine]
            OBS[Observability / Telemetry / Audit]
            BUD[Budget + Rate Controls]
            MEM[State Store / Memory / Session Context]
            VC[Vector Store / Retrieval]
            TOOLS[Tools / APIs / CLI / GitHub / Azure / Kusto / Terraform]
        end

        subgraph LLMZone["Deep Reasoning Tier"]
            L1[Reasoning LLM]
            L2[Code / Analysis LLM]
            L3[Research / Synthesis LLM]
        end

        subgraph Providers["Provider Layer"]
            P1[OpenAI / Azure OpenAI]
            P2[Other Model Providers]
            P3[Local Hosted Models]
        end
    end

    subgraph Edge["PhoenixRooivalk Edge Plane"]
        RP[Signal / Detection Pipeline]
        ER1[Edge SLM: Event Labeler]
        ER2[Edge SLM: Threat Summarizer]
        ER3[Edge SLM: Alert Composer]
        ER4[Edge SLM: Escalation Filter]
        OC[Operator Console]
    end

    U1 --> GW
    U2 --> GW
    U3 --> GW
    U4 --> GW
    U5 --> RP

    GW --> S1
    S1 --> S2
    S2 --> S3
    S3 --> S4
    S4 --> S5
    S5 --> S6

    S2 --> POL
    S3 --> BUD
    S4 --> MEM
    S5 --> VC
    S6 --> OBS

    S6 --> CM
    S6 --> AF
    S6 --> CF
    S6 --> L1
    S6 --> L2
    S6 --> L3

    CM --> MEM
    CM --> TOOLS
    CM --> L1

    AF --> MEM
    AF --> TOOLS
    AF --> L2

    CF --> MEM
    CF --> TOOLS
    CF --> L2

    L1 --> P1
    L2 --> P1
    L3 --> P2
    L2 --> P3

    RP --> ER1
    ER1 --> ER2
    ER2 --> ER3
    ER3 --> OC
    ER2 --> ER4
    ER4 --> GW
```

## System Responsibilities

### AI Gateway

The front door that owns:

- Request intake
- Classification
- Safety checks
- Budget-aware routing
- Cache decisions
- Escalation decisions

### Cognitive Mesh

The orchestration brain for multi-agent work:

- Specialist routing
- Decomposition
- Shared state coordination

### AgentKit Forge

The tool execution runtime:

- Tool selection
- Parameter extraction
- Execution loops

### CodeFlow Engine

The CI/CD intelligence plane:

- PR/diff triage
- CI failure bucketing
- Contract breakage interpretation

### PhoenixRooivalk

The edge interpretation plane:

- Event labeling
- Operator alert generation
- Low-bandwidth summaries

---

## Control Plane vs Execution Plane

```mermaid
flowchart LR
    subgraph CP["Control Plane"]
        A[AI Gateway]
        B[SLM Routing]
        C[Policy Engine]
        D[Budget Controls]
        E[Observability]
        F[State / Memory]
    end

    subgraph EP["Execution Plane"]
        G[Cognitive Mesh]
        H[AgentKit Forge]
        I[CodeFlow Engine]
        J[LLM Providers]
        K[Tools / APIs]
        L[PhoenixRooivalk Edge]
    end

    A --> B
    B --> G
    B --> H
    B --> I
    B --> J
    G --> K
    H --> K
    I --> K
    L --> A
    C --> A
    D --> A
    E --> A
    F --> G
    F --> H
    F --> I
```

---

## SLM Tier vs LLM Tier

```mermaid
flowchart TD
    IN[Request / Event / Telemetry] --> SLM[SLM Tier]

    subgraph SLMOps["SLM Responsibilities"]
        S1[Classify]
        S2[Screen]
        S3[Route]
        S4[Compress]
        S5[Validate]
        S6[Triage]
    end

    SLM --> S1
    SLM --> S2
    SLM --> S3
    SLM --> S4
    SLM --> S5
    SLM --> S6

    S3 --> D{Escalate?}
    D -->|No| OUT1[Fast / Cheap Response]
    D -->|Yes| LLM[LLM Tier]

    subgraph LLMOps["LLM Responsibilities"]
        L1[Deep reasoning]
        L2[Complex synthesis]
        L3[Ambiguous tradeoffs]
        L4[Novel plan generation]
    end

    LLM --> L1
    LLM --> L2
    LLM --> L3
    LLM --> L4
    LLM --> OUT2[High-value response]
```

---

## Practical Request Path (AI Gateway)

```mermaid
sequenceDiagram
    participant C as Client
    participant G as AI Gateway
    participant S as SLM Layer
    participant T as Tools
    participant M as Mesh
    participant L as LLM
    participant O as Observability

    C->>G: Request
    G->>S: classify + scan + estimate complexity
    S-->>G: route decision + confidence
    G->>O: log request metadata

    alt Simple
        G-->>C: direct low-cost response
    else Tool-first
        G->>M: dispatch task
        M->>T: execute tools
        T-->>M: tool results
        M->>S: compress results
        S-->>M: compact state
        M-->>C: response
    else Complex
        G->>L: escalate with compact context
        L-->>G: deep reasoning output
        G-->>C: final response
    end
```

---

## CodeFlow Engine CI Path

```mermaid
flowchart TD
    PR[PR / Push / Issue Event] --> C1[SLM Diff Classifier]
    C1 --> C2[SLM Risk Scorer]
    C2 --> C3[SLM Test Impact Predictor]

    C3 --> D{Path}
    D -->|low risk| F1[Fast checks]
    D -->|high risk| F2[Full CI / security / contract tests]
    D -->|uncertain| F3[LLM or human review gate]

    F1 --> L[CI Logs]
    F2 --> L
    F3 --> L

    L --> T1[SLM Failure Triage]
    T1 --> T2[SLM Comment Draft / Routing]
    T2 --> T3[Action: retry / assign / block / suggest fix]
```

---

## AgentKit Forge Tool Loop

```mermaid
flowchart LR
    A[Task] --> B[SLM Tool Selector]
    B --> C[Select Tool + Args]

    C --> D1[GitHub]
    C --> D2[Azure]
    C --> D3[Terraform]
    C --> D4[Kusto]
    C --> D5[Docs / Files]

    D1 --> E[SLM Result Compressor]
    D2 --> E
    D3 --> E
    D4 --> E
    D5 --> E

    E --> F{Enough?}
    F -->|yes| G[Return answer]
    F -->|no| H[Escalate to LLM / Mesh]
```

---

## PhoenixRooivalk Edge Path

```mermaid
sequenceDiagram
    participant S as Sensors
    participant P as Detection Pipeline
    participant E as Edge SLM
    participant O as Operator Console
    participant C as Cloud Gateway

    S->>P: RF / EO / radar / telemetry
    P->>E: normalized event packet
    E-->>P: label + summary + confidence
    P->>O: operator alert

    alt threshold exceeded
        P->>C: send compressed evidence bundle
    else local-only event
        P->>O: keep local record
    end
```

---

## Layer Responsibilities

| Layer         | Primary                        | SLM Role                | LLM Role             |
| ------------- | ------------------------------ | ----------------------- | -------------------- |
| Edge          | PhoenixRooivalk                | Reports only            | None                 |
| Gateway       | AI Gateway                     | Routing, security, cost | Complex reasoning    |
| Orchestration | Cognitive Mesh, AgentKit Forge | Routing, tools          | Synthesis            |
| Intelligence  | CodeFlow Engine                | Triage                  | None                 |
| Synthesis     | LLM Layer                      | None                    | Reasoning, synthesis |

---

## Ownership Boundaries

### AI Gateway owns

- Ingress control
- Policy enforcement
- Routing
- Cost governance
- Model/provider abstraction
- Shared telemetry

### Cognitive Mesh owns

- Multi-agent coordination
- Task decomposition
- State fusion
- Escalation into deep synthesis

### AgentKit Forge owns

- Tool loops
- Action execution
- Extraction
- Retry/fallback behavior

### CodeFlow Engine owns

- Software delivery intelligence
- Repo event interpretation
- CI analysis
- Developer feedback automation

### PhoenixRooivalk owns

- Edge summarization
- Local alerting
- Compressed event escalation

---

## Implementation Phases

### Phase 1 — Gateway-first

Build SLM control plane: intent classifier, policy scanner, budget router, cache gate, escalation judge

### Phase 2 — CodeFlow Engine

Add SLMs: diff classifier, PR risk scorer, CI failure bucketer

### Phase 3 — AgentKit Forge

Optimize tool loops: tool selector, arg extractor, result compressor

### Phase 4 — Cognitive Mesh

Add: specialist router, decomposer, state manager

### Phase 5 — PhoenixRooivalk

Deploy edge SLMs: event label, alert text, escalation filter

---

## Shared Telemetry Schema

```json
{
  "trace_id": "uuid",
  "system": "ai-gateway|cognitive-mesh|codeflow-engine|agentkit-forge|phoenixrooivalk",
  "stage": "classify|route|tool_call|llm_escalation|edge_alert",
  "model_tier": "slm|llm",
  "model_name": "example-model",
  "decision": "allow|block|tool_first|escalate|local_only",
  "confidence": 0.92,
  "latency_ms": 83,
  "token_in": 540,
  "token_out": 96,
  "estimated_cost": 0.0014,
  "policy_flags": ["pii:none", "secret:none"],
  "outcome": "success"
}
```

---

## Production Rules

### Escalate to LLM when:

- Confidence below threshold
- Ambiguity above threshold
- Multiple specialists disagree
- Tool results conflict
- Output is user-facing and high-stakes
- Architecture/tradeoff reasoning required

### Stay in SLM path when:

- Task is classification
- Task is screening
- Task is extraction
- Task is summarization
- Task is repetitive CI triage
- Task is edge-local operator support

---

## C4-Style Architecture

For detailed C4-style diagrams including:

- System Context diagram
- Container diagram
- CodeFlow sequence
- PhoenixRooivalk edge-to-cloud sequence

See [c4-architecture.md](c4-architecture.md)

---

## Bottom Line

The most practical target architecture:

- **AI Gateway** as the centralized SLM control plane
- **Cognitive Mesh / AgentKit Forge / CodeFlow Engine** as execution systems
- **PhoenixRooivalk** as edge plane with local SLM autonomy
- **LLMs** reserved for synthesis, ambiguity, and hard reasoning

> Gateway governs. SLMs triage and steer. Specialist systems execute. LLMs arbitrate the hard cases. Edge stays local unless escalation is justified.
