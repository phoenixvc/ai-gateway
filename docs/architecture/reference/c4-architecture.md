# C4-Style Architecture

This section provides C4-style diagrams showing system context, containers, and key sequences.

## 1. System Context

This shows the major external actors and the five core systems.

```mermaid
flowchart TB
    User[Users / Operators / Developers]
    Apps[Client Apps / Internal Portals / APIs]
    GitHub[GitHub / CI Events / PRs / Issues]
    Sensors[PhoenixRooivalk Sensors / RF / EO / Radar / Telemetry]
    Providers[Model Providers / Hosted Models]
    Tools[Azure / Terraform / Kusto / GitHub APIs / Internal Tools]

    subgraph Platform["PhoenixVC AI Platform"]
        AIG[AI Gateway]
        CM[Cognitive Mesh]
        CFE[CodeFlow Engine]
        AKF[AgentKit Forge]
        PR[PhoenixRooivalk Edge + Command Layer]
    end

    User --> AIG
    Apps --> AIG
    GitHub --> CFE
    Sensors --> PR

    AIG --> CM
    AIG --> CFE
    AIG --> AKF
    AIG --> PR

    CM --> Providers
    CFE --> Providers
    AKF --> Providers
    AIG --> Providers

    CM --> Tools
    CFE --> Tools
    AKF --> Tools
    PR --> AIG
```

### External Actors

| Actor                          | Role                                       |
| ------------------------------ | ------------------------------------------ |
| Users / Operators / Developers | Initiate requests, reviews, investigations |
| Apps / APIs                    | Consume AI control plane programmatically  |
| GitHub                         | Triggers software delivery workflows       |
| Sensors                        | Produce edge telemetry                     |
| Model Providers                | Serve LLM/SLM inference                    |
| Tools                          | Execution surfaces, enterprise integration |

### System Roles

| System          | Role                                         |
| --------------- | -------------------------------------------- |
| AI Gateway      | Front door, routing, policy, budget, caching |
| Cognitive Mesh  | Multi-agent coordination and synthesis       |
| CodeFlow Engine | SDLC/CI intelligence                         |
| AgentKit Forge  | Tool-driven agent execution                  |
| PhoenixRooivalk | Edge detection interpretation                |

---

## 2. Container Diagram

```mermaid
flowchart TB
    subgraph Clients["Clients / Event Sources"]
        C1[Web UI / Chat UI]
        C2[Internal Apps / APIs]
        C3[GitHub Webhooks]
        C4[Operator Console]
    end

    subgraph Gateway["AI Gateway"]
        G1[Ingress API]
        G2[SLM Classifier]
        G3[Policy Scan]
        G4[Budget Router]
        G5[Semantic Cache]
        G6[Escalation Judge]
    end

    subgraph Mesh["Cognitive Mesh"]
        M1[Specialist Router]
        M2[Task Decomposer]
        M3[State Manager]
        M4[Synthesis Coordinator]
    end

    subgraph Forge["AgentKit Forge"]
        F1[Tool Selector]
        F2[Argument Extractor]
        F3[Execution Loop]
        F4[Result Compressor]
    end

    subgraph CodeFlow["CodeFlow Engine"]
        CF1[PR / Diff Classifier]
        CF2[Risk Scorer]
        CF3[CI Failure Triage]
        CF4[Review / Action Engine]
    end

    subgraph Shared["Shared Platform Services"]
        S1[Policy Engine]
        S2[Observability]
        S3[State Store]
        S4[Vector Store]
        S5[Tool Broker]
    end

    subgraph Models["Model Tier"]
        ML1[SLM Pool]
        ML2[LLM Pool]
    end

    subgraph Edge["PhoenixRooivalk Edge"]
        E1[Detection Pipeline]
        E2[Edge SLM Event Labeler]
        E3[Edge SLM Summarizer]
        E4[Edge Escalation Filter]
    end

    C1 --> G1
    C2 --> G1
    C3 --> CF1
    C4 --> G1

    G1 --> G2
    G2 --> G3
    G3 --> G4
    G4 --> G5
    G5 --> G6

    G6 --> M1
    G6 --> F1
    G6 --> CF1
    G6 --> ML2

    M1 --> M2
    M2 --> M3
    M3 --> M4

    F1 --> F2
    F2 --> F3
    F3 --> F4

    CF1 --> CF2
    CF2 --> CF3
    CF3 --> CF4

    G3 --> S1
    G6 --> S2
    M3 --> S3
    G5 --> S3
    G5 --> S4
    F3 --> S5
    CF4 --> S5

    E1 --> E2
    E2 --> E3
    E3 --> E4
    E4 --> G1
```

### Container Responsibilities

#### AI Gateway

| Container        | Responsibility                   |
| ---------------- | -------------------------------- |
| Ingress API      | Entry point                      |
| SLM Classifier   | Intent/complexity classification |
| Policy Scan      | Safety/compliance gate           |
| Budget Router    | Tier selection                   |
| Semantic Cache   | Avoid redundant inference        |
| Escalation Judge | Small-vs-large decision          |

#### Cognitive Mesh

| Container             | Responsibility   |
| --------------------- | ---------------- |
| Specialist Router     | Picks agent(s)   |
| Task Decomposer       | Splits work      |
| State Manager         | Compressed state |
| Synthesis Coordinator | Merge + escalate |

#### AgentKit Forge

| Container          | Responsibility     |
| ------------------ | ------------------ |
| Tool Selector      | Chooses tool       |
| Argument Extractor | Structured inputs  |
| Execution Loop     | Run/retry/fallback |
| Result Compressor  | Distills output    |

#### CodeFlow Engine

| Container            | Responsibility      |
| -------------------- | ------------------- |
| PR/Diff Classifier   | File classification |
| Risk Scorer          | Risk assessment     |
| CI Failure Triage    | Failure bucketing   |
| Review/Action Engine | Routing/actions     |

#### PhoenixRooivalk Edge

| Container              | Responsibility     |
| ---------------------- | ------------------ |
| Detection Pipeline     | Signal processing  |
| Edge Event Labeler     | Labels events      |
| Edge Summarizer        | Operator summaries |
| Edge Escalation Filter | Cloud escalation   |

---

## 3. CodeFlow Sequence

```mermaid
sequenceDiagram
    participant GH as GitHub
    participant CF as CodeFlow
    participant SLM as SLM Tier
    participant TO as CI / Tool Broker
    participant GW as AI Gateway
    participant LLM as LLM Tier

    GH->>CF: PR opened / updated
    CF->>SLM: classify files + intent
    SLM-->>CF: infra-change, high risk

    CF->>TO: trigger CI / contract checks
    TO-->>CF: logs, results

    CF->>SLM: triage failures
    SLM-->>CF: breaking change detected

    CF->>GW: request remediation
    GW->>LLM: analyze + explain
    LLM-->>GW: remediation steps
    GW-->>CF: response

    CF-->>GH: PR comment with findings
```

### SLM Handles

- File classification
- Risk scoring
- Log bucketing
- Cause identification

### LLM Handles

- Remediation proposals
- Tradeoff explanation
- Evidence synthesis

---

## 4. PhoenixRooivalk Sequence

```mermaid
sequenceDiagram
    participant Sensors
    participant DP as Detection Pipeline
    participant ESLM as Edge SLM
    participant OC as Operator Console
    participant GW as AI Gateway
    participant CM as Cognitive Mesh
    participant LLM as Cloud LLM

    Sensors->>DP: raw detections
    DP->>ESLM: normalized event
    ESLM-->>DP: label + summary + confidence

    DP->>OC: local alert

    alt Below threshold
        DP->>OC: local record
    else Above threshold
        DP->>GW: compressed bundle
        GW->>CM: route to workflow
        CM->>LLM: deep analysis
        LLM-->>CM: interpretation
        CM-->>GW: response
        GW-->>OC: escalated advisory
    end
```

### Design Intent

- Label events
- Summarize meaning
- Suppress noise
- Conserve bandwidth
- Escalate only when justified

---

## 5. C4 Narrative

### System Context

The platform provides a unified AI control plane for developer workflows, agent orchestration, and edge intelligence.

### Container View

| Layer           | Description                              |
| --------------- | ---------------------------------------- |
| Control-plane   | Classification, policy, routing, caching |
| Execution       | Orchestration, tools, CI, edge           |
| Shared services | Policy, retrieval, memory, telemetry     |
| Model           | SLM and LLM workloads                    |
| Edge            | Local interpretation + escalation        |

### Dynamic Patterns

| Pattern        | System          | Description          |
| -------------- | --------------- | -------------------- |
| Gateway triage | AI Gateway      | Selective escalation |
| Repo triage    | CodeFlow        | Remediation          |
| Multi-agent    | Cognitive Mesh  | State compression    |
| Tool loops     | AgentKit Forge  | Result distillation  |
| Edge-first     | PhoenixRooivalk | Threshold escalation |
