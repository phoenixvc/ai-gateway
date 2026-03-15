# Deployment, Trust Boundaries & Observability

This set extends the C4 view into operational architecture including deployment, security boundaries, and telemetry.

---

## 1. Deployment Diagram

This is the practical cloud/edge deployment shape for your stack.

```mermaid
flowchart TB
    subgraph Internet["Public / External"]
        U1[Users / Browsers / Chat Clients]
        U2[GitHub Webhooks]
        U3[External APIs / Apps]
        MP[Model Providers]
    end

    subgraph Azure["Azure Subscription"]
        DNS[Azure DNS / Front Door / App Gateway]
        KV[Key Vault]
        LAW[Log Analytics]
        ADX[Azure Data Explorer / Kusto]
        BLOB[Blob Storage]
        REDIS[Redis / Cache]
        DB[Postgres / Cosmos / State DB]
        AISEARCH[Vector Store / AI Search]
        GRAF[Grafana]
        BUS[Service Bus / Queue]
        MON[Azure Monitor / App Insights]

        subgraph Runtime["Runtime Plane"]
            GW[AI Gateway]
            CM[Cognitive Mesh]
            AKF[AgentKit Forge]
            CFE[CodeFlow Engine]
            TB[Tool Broker]
            OPA[Policy Engine]
        end

        subgraph Workers["Background / Event Workers"]
            W1[PR / CI Worker]
            W2[Agent Task Worker]
            W3[Telemetry Ingest Worker]
            W4[Cost / Audit Aggregator]
        end

        subgraph Models["Hosted Model Zone"]
            SLM[SLM Serving Pool]
            LLM[LLM Adapter / Provider Proxy]
        end
    end

    subgraph Edge["PhoenixRooivalk Edge Sites"]
        SENS[RF / EO / Radar / Telemetry Sensors]
        EDGEPIPE[Detection Pipeline]
        E1[Edge SLM Event Labeler]
        E2[Edge SLM Summarizer]
        E3[Edge Escalation Filter]
        OPC[Operator Console]
        SYNC[Secure Sync Agent]
    end

    U1 --> DNS
    U2 --> DNS
    U3 --> DNS
    DNS --> GW

    GW --> REDIS
    GW --> DB
    GW --> AISEARCH
    GW --> KV
    GW --> OPA
    GW --> TB
    GW --> SLM
    GW --> LLM
    GW --> MON

    CM --> DB
    CM --> BUS
    CM --> AISEARCH
    CM --> TB
    CM --> SLM
    CM --> LLM
    CM --> MON

    AKF --> DB
    AKF --> BUS
    AKF --> TB
    AKF --> SLM
    AKF --> LLM
    AKF --> MON

    CFE --> DB
    CFE --> BUS
    CFE --> TB
    CFE --> SLM
    CFE --> LLM
    CFE --> MON

    W1 --> CFE
    W2 --> AKF
    W3 --> GW
    W4 --> ADX

    MON --> LAW
    LAW --> ADX
    BLOB --> ADX
    ADX --> GRAF

    MP --> LLM

    SENS --> EDGEPIPE
    EDGEPIPE --> E1
    E1 --> E2
    E2 --> E3
    E2 --> OPC
    E3 --> SYNC
    SYNC --> GW
```

### Practical Reading of Deployment

| Zone                 | Components                                                | Purpose                 |
| -------------------- | --------------------------------------------------------- | ----------------------- |
| **Front door**       | Azure DNS / Front Door / App Gateway                      | Ingress and routing     |
| **Shared backing**   | Key Vault, Redis, Postgres/Cosmos, AI Search, Service Bus | State, caching, secrets |
| **Runtime services** | AI Gateway, Cognitive Mesh, AgentKit Forge, CodeFlow      | Core execution          |
| **Workers**          | PR/CI, Agent Task, Telemetry, Cost Aggregators            | Background processing   |
| **Model zone**       | SLM Pool, LLM Adapter                                     | AI inference            |
| **Edge**             | Detection Pipeline, Edge SLMs, Operator Console           | Local operation         |

---

## 2. Trust Boundary Diagram

This is the security-relevant segmentation.

```mermaid
flowchart LR
    subgraph TB1["Boundary 1: Public / Untrusted"]
        A[Users / Browsers]
        B[GitHub Webhooks]
        C[External Apps]
        D[Internet Traffic]
    end

    subgraph TB2["Boundary 2: Controlled Ingress"]
        E[Front Door / API Gateway / WAF]
        F[AI Gateway]
    end

    subgraph TB3["Boundary 3: Internal Control Plane"]
        G[Policy Engine]
        H[Budget / Rate Controls]
        I[Session / State Store]
        J[Semantic Cache]
        K[Observability / Audit]
    end

    subgraph TB4["Boundary 4: Internal Execution Plane"]
        L[Cognitive Mesh]
        M[AgentKit Forge]
        N[CodeFlow Engine]
        O[Tool Broker]
    end

    subgraph TB5["Boundary 5: Sensitive Integration Zone"]
        P[Key Vault]
        Q[Azure APIs]
        R[GitHub APIs]
        S[Kusto / Terraform / Internal Tools]
    end

    subgraph TB6["Boundary 6: External Model Providers"]
        T[LLM Providers]
        U[Hosted / External SLM Providers]
    end

    subgraph TB7["Boundary 7: Edge / Field Environment"]
        V[PhoenixRooivalk Edge Node]
        W[Sensors]
        X[Operator Console]
    end

    A --> E
    B --> E
    C --> E
    D --> E
    E --> F

    F --> G
    F --> H
    F --> I
    F --> J
    F --> K

    F --> L
    F --> M
    F --> N
    L --> O
    M --> O
    N --> O

    O --> Q
    O --> R
    O --> S
    F --> P
    L --> P
    M --> P
    N --> P

    F --> T
    F --> U
    L --> T
    M --> T
    N --> T

    W --> V
    V --> X
    V --> F
```

### Security Interpretation

| Boundary  | Description                                                                               |
| --------- | ----------------------------------------------------------------------------------------- |
| **1 → 2** | Treat all inbound as hostile until authenticated, rate-limited, schema-validated, logged  |
| **2 → 3** | AI Gateway is the only entry into internal AI control plane                               |
| **3 → 4** | Control-plane services decide policy, routing, cost, escalation                           |
| **4 → 5** | Sensitive zone: credentials, infra mutation, production APIs, write actions               |
| **6**     | External providers are semi-trusted - apply output scanning and redaction                 |
| **7**     | Edge nodes are partially disconnected - need signed software, local audit, encrypted sync |

---

## 3. Observability Architecture

This is the unified telemetry design across all systems.

```mermaid
flowchart TB
    subgraph Producers["Telemetry Producers"]
        P1[AI Gateway]
        P2[Cognitive Mesh]
        P3[AgentKit Forge]
        P4[CodeFlow Engine]
        P5[PhoenixRooivalk Edge]
        P6[Tool Broker]
        P7[Policy Engine]
    end

    subgraph Signals["Signal Types"]
        S1[Request / Response Logs]
        S2[Routing Decisions]
        S3[Policy Events]
        S4[Tool Calls]
        S5[Model Usage]
        S6[CI / PR Events]
        S7[Edge Detection Events]
        S8[Cost / Token Metrics]
        S9[Audit Trail]
    end

    subgraph Ingest["Ingestion"]
        I1[OpenTelemetry Collectors]
        I2[Azure Monitor / App Insights]
        I3[Blob Export]
        I4[Log Analytics]
    end

    subgraph Analytics["Analytics / Query"]
        A1[Azure Data Explorer / Kusto]
        A2[Cost Aggregates]
        A3[Decision Quality Metrics]
        A4[Security / Audit Views]
    end

    subgraph Viz["Visualization / Alerting"]
        V1[Grafana Dashboards]
        V2[Alerts / On-call]
        V3[Ops Runbooks]
        V4[Executive Cost Views]
    end

    P1 --> S1
    P1 --> S2
    P1 --> S5
    P1 --> S8
    P1 --> S9

    P2 --> S2
    P2 --> S4
    P2 --> S5
    P2 --> S9

    P3 --> S4
    P3 --> S5
    P3 --> S9

    P4 --> S6
    P4 --> S2
    P4 --> S5
    P4 --> S9

    P5 --> S7
    P5 --> S2
    P5 --> S9

    P6 --> S4
    P7 --> S3

    S1 --> I1
    S2 --> I1
    S3 --> I1
    S4 --> I1
    S5 --> I2
    S6 --> I2
    S7 --> I3
    S8 --> I2
    S9 --> I4

    I1 --> A1
    I2 --> A1
    I3 --> A1
    I4 --> A1

    A1 --> A2
    A1 --> A3
    A1 --> A4

    A2 --> V1
    A3 --> V1
    A4 --> V1
    V1 --> V2
    V1 --> V3
    V1 --> V4
```

### What to Measure

#### Gateway metrics

- Requests by route
- SLM vs LLM escalation rate
- Confidence distribution
- Token in/out averages
- Semantic cache hit rate
- Refusal/block counts
- Provider latency/error rate

#### Cognitive Mesh metrics

- Route-to-specialist distribution
- Decomposition count per task
- Summary compression ratio
- Multi-agent disagreement rate
- Escalation rate to LLM synthesis

#### AgentKit Forge metrics

- Tool selection accuracy
- Retry counts
- Fallback frequency
- Avg tool-loop depth
- Tool output compression ratio

#### CodeFlow Engine metrics

- PR classification distribution
- False positive/negative on risk tier
- CI failure bucket frequency
- Contract-break detection precision
- Comment usefulness feedback

#### PhoenixRooivalk metrics

- Local-only vs escalated events
- Edge summary latency
- Alert volume per session
- Signal-to-alert compression ratio
- Dropped/deferred syncs
