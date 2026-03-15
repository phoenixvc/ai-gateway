# Deployment and Trust Boundaries

Status: Accepted

## Context

The system interacts with external users, internal services, model providers, and edge devices. Clear trust boundaries must be established.

## Trust Boundary Diagram

```mermaid
flowchart LR
    subgraph Public
        A[Users]
        B[GitHub]
        C[External Apps]
    end

    subgraph Ingress
        D[API Gateway / WAF]
        E[AI Gateway]
    end

    subgraph ControlPlane
        F[Policy Engine]
        G[Session Store]
        H[Semantic Cache]
        I[Observability]
    end

    subgraph Execution
        J[Cognitive Mesh]
        K[AgentKit Forge]
        L[CodeFlow Engine]
    end

    subgraph Integration
        M[Key Vault]
        N[Azure APIs]
        O[GitHub APIs]
    end

    subgraph ExternalModels
        P[LLM Providers]
    end

    subgraph Edge
        Q[PhoenixRooivalk Node]
        R[Sensors]
    end

    A --> D
    B --> D
    C --> D
    D --> E

    E --> F
    E --> G
    E --> H
    E --> I

    E --> J
    E --> K
    E --> L

    J --> N
    K --> N
    L --> O

    E --> M
    E --> P

    R --> Q
    Q --> E
```

## Security Principles

- **Gateway is the only public AI ingress.**
- **Secrets only accessed through Key Vault.**
- **Tool access occurs through controlled brokers.**
- **Edge nodes operate under constrained trust.**
