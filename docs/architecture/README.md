# Architecture

This directory contains system architecture documentation for the AI Gateway and related systems.

## Overview

The architecture follows a layered approach combining:

- **SLMs (Small Language Models)** for cost-effective routing, classification, and tool selection
- **LLMs** for complex reasoning and final synthesis

### Canonical Principle

> **Use SLMs to decide, filter, classify, compress, and prepare.**
> **Use LLMs to reason, reconcile, synthesize, and communicate.**

## Documentation Structure

```
docs/architecture/
├── README.md                    # This file
├── 01-system-context.md         # ADR: System Context
├── 02-container-architecture.md # ADR: Container Architecture
├── 03-deployment-trust-boundaries.md # ADR: Deployment & Trust Boundaries
├── 04-observability-telemetry.md    # ADR: Observability & Telemetry
├── 05-slm-llm-decision-flow.md   # ADR: SLM→LLM Decision Flow
├── 06-shared-contracts.md       # ADR: Shared Contracts
├── 07-repo-ownership-map.md      # ADR: Repository Ownership
├── systems/                     # Individual system documentation
│   ├── ai-gateway.md
│   ├── cognitive-mesh.md
│   ├── codeflow-engine.md
│   ├── agentkit-forge.md
│   ├── phoenix-rooivalk.md
│   └── mystira.md
└── reference/                   # Reference and planning docs
    ├── cross-system.md
    ├── c4-architecture.md
    ├── deployment-observability.md
    ├── contracts.md
    ├── operations-patterns.md
    ├── dashboards.md
    ├── slm-implementation-matrix.md
    ├── slm-management-plan.md
    ├── matrix-gateway.md
    ├── matrix-cognitive-mesh.md
    ├── matrix-codeflow.md
    ├── matrix-agentkit.md
    ├── matrix-rooivalk.md
    ├── matrix-mystira.md
    └── strategic/                # Strategic guidance
        ├── README.md
        ├── 01-why-slms-matter.md
        ├── 02-gateway-slm-use-cases.md
        ├── 03-cognitive-mesh-use-cases.md
        ├── 04-codeflow-use-cases.md
        ├── 05-agentkit-use-cases.md
        ├── 06-rooivalk-use-cases.md
        ├── 07-deployment-model.md
        └── 08-implementation-order.md
```

docs/architecture/
├── README.md # This file
├── systems/ # Individual system documentation
│ ├── ai-gateway.md
│ ├── cognitive-mesh.md
│ ├── codeflow-engine.md
│ ├── agentkit-forge.md
│ ├── phoenix-rooivalk.md
│ └── mystira.md
└── reference/ # Reference and planning docs
├── cross-system.md
├── c4-architecture.md
├── deployment-observability.md
├── contracts.md
├── operations-patterns.md
├── dashboards.md
├── slm-implementation-matrix.md
├── slm-management-plan.md
├── matrix-gateway.md
├── matrix-cognitive-mesh.md
├── matrix-codeflow.md
├── matrix-agentkit.md
├── matrix-rooivalk.md
├── matrix-mystira.md
└── strategic/ # Strategic guidance
├── README.md
├── 01-why-slms-matter.md
├── 02-gateway-slm_use-cases.md
├── 03-cognitive-mesh-use-cases.md
├── 04-codeflow-use-cases.md
├── 05-agentkit-use-cases.md
├── 06-rooivalk-use-cases.md
├── 07-deployment-model.md
└── 08-implementation-order.md

```

docs/architecture/
├── README.md # This file
├── systems/ # Individual system documentation
│ ├── ai-gateway.md
│ ├── cognitive-mesh.md
│ ├── codeflow-engine.md
│ ├── agentkit-forge.md
│ ├── phoenix-rooivalk.md
│ └── mystira.md
└── reference/ # Reference and planning docs
├── cross-system.md
├── slm-implementation-matrix.md
├── slm-management-plan.md
├── matrix-gateway.md
├── matrix-cognitive-mesh.md
├── matrix-codeflow.md
├── matrix-agentkit.md
├── matrix-rooivalk.md
├── matrix-mystira.md
└── strategic/ # Strategic guidance
├── README.md
├── 01-why-slms-matter.md
├── 02-gateway-slm-use-cases.md
├── 03-cognitive-mesh-use-cases.md
├── 04-codeflow-use-cases.md
├── 05-agentkit-use-cases.md
├── 06-rooivalk-use-cases.md
├── 07-deployment-model.md
└── 08-implementation-order.md

```

### Systems

- [systems/ai-gateway.md](systems/ai-gateway.md) - AI Gateway: SLM as admission control & routing
- [systems/cognitive-mesh.md](systems/cognitive-mesh.md) - Agent orchestration: routing, decomposition
- [systems/codeflow-engine.md](systems/codeflow-engine.md) - CI/CD intelligence: PR triage, log analysis
- [systems/agentkit-forge.md](systems/agentkit-forge.md) - Agent building: tool selection, context compression
- [systems/phoenix-rooivalk.md](systems/phoenix-rooivalk.md) - Edge AI: SLM for reports only (NOT control)
- [systems/mystira.md](systems/mystira.md) - Story generation: SLM as moderation, age-fit, continuity layer

### Reference

- [reference/cross-system.md](reference/cross-system.md) - How all systems integrate
- [reference/c4-architecture.md](reference/c4-architecture.md) - C4-style diagrams (context, containers, sequences)
- [reference/deployment-observability.md](reference/deployment-observability.md) - Deployment, trust boundaries, observability
- [reference/contracts.md](reference/contracts.md) - Shared JSON schemas for telemetry and routing
- [reference/operations-patterns.md](reference/operations-patterns.md) - SLM→LLM decision flows, ownership, implementation
- [reference/dashboards.md](reference/dashboards.md) - Recommended Grafana/ADX dashboards
- [reference/slm-implementation-matrix.md](reference/slm-implementation-matrix.md) - Overview with threshold summary
- [reference/slm-management-plan.md](reference/slm-management-plan.md) - Cross-project SLM management

### Strategic Guidance

- [reference/strategic/README.md](reference/strategic/README.md) - Strategic SLM guidance index
- [reference/strategic/01-why-slms-matter.md](reference/strategic/01-why-slms-matter.md) - Executive summary
- [reference/strategic/02-gateway-slm-use-cases.md](reference/strategic/02-gateway-slm-use-cases.md) - AI Gateway use cases
- [reference/strategic/03-cognitive-mesh-use-cases.md](reference/strategic/03-cognitive-mesh-use-cases.md) - Cognitive Mesh use cases
- [reference/strategic/04-codeflow-use-cases.md](reference/strategic/04-codeflow-use-cases.md) - CodeFlow Engine use cases
- [reference/strategic/05-agentkit-use-cases.md](reference/strategic/05-agentkit-use-cases.md) - AgentKit Forge use cases
- [reference/strategic/06-rooivalk-use-cases.md](reference/strategic/06-rooivalk-use-cases.md) - PhoenixRooivalk use cases
- [reference/strategic/07-deployment-model.md](reference/strategic/07-deployment-model.md) - Deployment model
- [reference/strategic/08-implementation-order.md](reference/strategic/08-implementation-order.md) - Implementation order

## Quick Reference

| System          | SLM Role                                  | Key Document                                               |
| --------------- | ----------------------------------------- | ---------------------------------------------------------- |
| AI Gateway      | routing, policy checks, cost prediction   | [systems/ai-gateway.md](systems/ai-gateway.md)             |
| Cognitive Mesh  | agent routing, task decomposition         | [systems/cognitive-mesh.md](systems/cognitive-mesh.md)     |
| PhoenixRooivalk | **operator summaries only**               | [systems/phoenix-rooivalk.md](systems/phoenix-rooivalk.md) |
| CodeFlow Engine | CI intelligence, log analysis             | [systems/codeflow-engine.md](systems/codeflow-engine.md)   |
| AgentKit Forge  | tool selection, context compression       | [systems/agentkit-forge.md](systems/agentkit-forge.md)     |
| Mystira         | story classification, moderation, age-fit | [systems/mystira.md](systems/mystira.md)                   |

## Implementation Order

1. **AI Gateway SLM router** — Highest immediate cost-leverage
2. **CodeFlow Engine CI/PR classifier** — Fastest operational value
3. **Cognitive Mesh decomposer/router** — Strong leverage once taxonomy stabilizes
4. **AgentKit Forge tool selector** — Useful once tool inventory is mature
5. **PhoenixRooivalk operator interpreter** — Valuable, keep isolated from critical control
6. **Mystira story control layer** — For child-safe story generation with SLM-based moderation

## Tiered Model Strategy

| Tier   | Use For               | Examples                                      |
| ------ | --------------------- | --------------------------------------------- |
| Tier 0 | deterministic/non-LLM | regex, schemas, policies                      |
| Tier 1 | SLM                   | classification, decomposition, tool selection |
| Tier 2 | LLM                   | synthesis, complex reasoning                  |

## Diagram Tools

This documentation uses **Mermaid** for inline diagrams (rendered in VS Code, GitHub, etc.).

For high-quality published diagrams, consider:

- **Figma MCP** - AI-powered Figma integration via VS Code extension
- **Mermaid Live Editor** - Online Mermaid diagram editing
- **Draw.io** - Traditional diagram editor

### Using Figma MCP for Architecture Diagrams

The [MCP Figma VS Code extension](https://github.com/sethdford/mcp-figma) enables AI-assisted diagram creation:

1. Install the extension in VS Code
2. Configure MCP server for your AI assistant
3. Use AI to generate and edit architecture diagrams in Figma

This is useful for creating polished, branded diagrams for presentations and documentation.

```

```
