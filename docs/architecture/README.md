# Architecture

This directory contains system architecture documentation for the AI Gateway and related systems.

## Overview

The architecture follows a layered approach combining:

- **SLMs (Small Language Models)** for cost-effective routing, classification, and tool selection
- **LLMs** for complex reasoning and final synthesis

## Documentation

### Core Concepts

- [README](README.md) - SLM fundamentals, characteristics, patterns
- [cross-system.md](cross-system.md) - How all systems integrate

### Project-Specific

- [ai-gateway.md](ai-gateway.md) - AI Gateway architecture
- [cognitive-mesh.md](cognitive-mesh.md) - Agent orchestration
- [phoenix-rooivalk.md](phoenix-rooivalk.md) - Edge AI system
- [codeflow-engine.md](codeflow-engine.md) - CI/CD intelligence
- [agentkit-forge.md](agentkit-forge.md) - Agent building framework

### Planning

- [slm-management-plan.md](slm-management-plan.md) - Cross-project SLM management

## Quick Reference

| System          | SLM Role                            | Key Document        |
| --------------- | ----------------------------------- | ------------------- |
| AI Gateway      | routing, policy checks              | ai-gateway.md       |
| Cognitive Mesh  | agent routing, task decomposition   | cognitive-mesh.md   |
| PhoenixRooivalk | edge telemetry analysis             | phoenix-rooivalk.md |
| CodeFlow Engine | CI intelligence, log analysis       | codeflow-engine.md  |
| AgentKit Forge  | tool selection, context compression | agentkit-forge.md   |
