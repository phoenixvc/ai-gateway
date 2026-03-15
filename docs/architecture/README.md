# Architecture

This directory contains system architecture documentation for the AI Gateway and related systems.

## Overview

The architecture follows a layered approach combining:

- **SLMs (Small Language Models)** for cost-effective routing, classification, and tool selection
- **LLMs** for complex reasoning and final synthesis

### Canonical Principle

> **Use SLMs to decide, filter, classify, compress, and prepare.**
> **Use LLMs to reason, reconcile, synthesize, and communicate.**

## Documentation

### Core Concepts

- [README](README.md) - SLM fundamentals, characteristics, patterns
- [cross-system.md](cross-system.md) - How all systems integrate

### Project-Specific

- [ai-gateway.md](ai-gateway.md) - AI Gateway: SLM as admission control & routing
- [cognitive-mesh.md](cognitive-mesh.md) - Agent orchestration: routing, decomposition
- [phoenix-rooivalk.md](phoenix-rooivalk.md) - Edge AI: SLM for reports only (NOT control)
- [codeflow-engine.md](codeflow-engine.md) - CI/CD intelligence: PR triage, log analysis
- [agentkit-forge.md](agentkit-forge.md) - Agent building: tool selection, context compression

### Planning

- [slm-management-plan.md](slm-management-plan.md) - Cross-project SLM management

## Quick Reference

| System          | SLM Role                                | Key Document        |
| --------------- | --------------------------------------- | ------------------- |
| AI Gateway      | routing, policy checks, cost prediction | ai-gateway.md       |
| Cognitive Mesh  | agent routing, task decomposition       | cognitive-mesh.md   |
| PhoenixRooivalk | **operator summaries only**             | phoenix-rooivalk.md |
| CodeFlow Engine | CI intelligence, log analysis           | codeflow-engine.md  |
| AgentKit Forge  | tool selection, context compression     | agentkit-forge.md   |

## Implementation Order

1. **AI Gateway SLM router** — Highest immediate cost-leverage
2. **CodeFlow Engine CI/PR classifier** — Fastest operational value
3. **Cognitive Mesh decomposer/router** — Strong leverage once taxonomy stabilizes
4. **AgentKit Forge tool selector** — Useful once tool inventory is mature
5. **PhoenixRooivalk operator interpreter** — Valuable, keep isolated from critical control

## Tiered Model Strategy

| Tier   | Use For               | Examples                                      |
| ------ | --------------------- | --------------------------------------------- |
| Tier 0 | deterministic/non-LLM | regex, schemas, policies                      |
| Tier 1 | SLM                   | classification, decomposition, tool selection |
| Tier 2 | LLM                   | synthesis, complex reasoning                  |
