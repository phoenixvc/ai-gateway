# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**ai-gateway** — OpenAI-compatible AI gateway built on LiteLLM, deployed to Azure Container Apps. Routes `/v1/responses` and `/v1/embeddings` to Azure OpenAI.

## Tech Stack

- **Gateway**: LiteLLM (Python)
- **Dashboard**: Node.js/pnpm (in `dashboard/`)
- **Infrastructure**: Terraform (>= 1.14.0) in `infra/`
- **State Service**: Custom state management in `state-service/`
- **Type Checking**: mypy
- **Scripts**: Deployment/setup scripts in `scripts/`

## Prerequisites

- Azure CLI (`az login`)
- Terraform >= 1.14.0

## Key Commands

```bash
# Dashboard
cd dashboard && pnpm install && pnpm dev

# Infrastructure
cd infra && terraform init && terraform plan

# Python
mypy .                    # Type check
python update_env_main.py # Update environment config
```

## Architecture

- `dashboard/` — Admin UI (Node.js/pnpm)
- `infra/` — Terraform IaC for Azure Container Apps
- `state-service/` — Gateway state management
- `scripts/` — Deployment automation
- `docs/` — Documentation

## AgentKit Forge

This project has not yet been onboarded to [AgentKit Forge](https://github.com/phoenixvc/agentkit-forge). To request onboarding, [create a ticket](https://github.com/phoenixvc/agentkit-forge/issues/new?title=Onboard+ai-gateway&labels=onboarding).
