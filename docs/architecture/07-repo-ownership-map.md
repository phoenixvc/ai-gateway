# Repository Ownership Map

Status: Accepted

## Repository Map

```mermaid
flowchart LR
    R1[pvc-ai-gateway] --> S1[AI Gateway Service]
    R2[cognitive-mesh] --> S2[Cognitive Mesh]
    R3[codeflow-engine] --> S3[CodeFlow Engine]
    R4[agentkit-forge] --> S4[AgentKit Forge]
    R5[phoenixrooivalk] --> S5[Rooivalk Edge / Command]
    R6[shared-contracts] --> S6[Shared Contracts]
    R7[infra] --> S7[Infrastructure / Monitoring]
```

## Ownership

| Repository           | Owns                                                   |
| -------------------- | ------------------------------------------------------ |
| **AI Gateway**       | request routing, policy enforcement, model abstraction |
| **Cognitive Mesh**   | orchestration, multi-agent coordination                |
| **CodeFlow Engine**  | CI/CD intelligence, PR analysis                        |
| **AgentKit Forge**   | tool-driven agents, execution runtime                  |
| **PhoenixRooivalk**  | edge telemetry, operator alerts                        |
| **Shared Contracts** | telemetry schema, routing decisions, audit envelope    |
| **Infrastructure**   | Azure deployment, monitoring, networking               |
