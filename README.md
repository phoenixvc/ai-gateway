# ai-flume

![Version](https://img.shields.io/badge/version-0.0.1-blue) ![Status](https://img.shields.io/badge/status-active-green) ![Platform](https://img.shields.io/badge/platform-Azure-0089D6)

> Shared AI infrastructure platform for phoenixvc — routing, observability, state, and cost attribution across all AI workloads.
>
> **ai-flume** is the data plane of the phoenixvc AI ecosystem. It routes every model request through a centralised LiteLLM gateway on Azure Container Apps, captures per-request telemetry via OpenTelemetry, persists attribution state for downstream cost analysis, and exposes a real-time Grafana dashboard.
>
> ---
>
> ## What it does
>
> - **Gateway** — OpenAI-compatible `/v1/chat/completions`, `/v1/responses`, and `/v1/embeddings` endpoints backed by Azure OpenAI. All requests pass through a single choke point for auth, rate-limiting, and observability.
> - - **State service** — FastAPI microservice that receives OTEL spans from the gateway and persists per-request attribution data (model, user, project, token counts) for consumption by `ai-gauge`.
>   - - **Dashboard** — Azure Container App serving a real-time Grafana-style spend and usage dashboard. Deployed as a standalone ACA module; can be embedded in `cockpit` via webview.
>     - - **Telemetry** — OpenTelemetry callback on every LiteLLM request. Pushes spans to Azure Application Insights and to the state service simultaneously.
>      
>       - ---
>
> ## Architecture
>
> ```
> clients (cockpit / ai-cadence / retort / cognitive-mesh)
>          │
>          ▼
>    ai-flume gateway  (LiteLLM on ACA)
>          │
>     ┌────┴────┐
>     │         │
>  Azure      OTEL spans
>  OpenAI      │
>              ▼
>       state-service  (FastAPI on ACA)
>              │
>              ├──▶  ai-gauge  (cost attribution)
>              └──▶  dashboard_aca  (real-time UI)
> ```
>
> **Three environments:** `dev` → `uat` → `prod`
> **Four Terraform modules:** `gateway`, `state_service`, `dashboard_aca`, `grafana_cloud`
>
> ---
>
> ## Repository layout
>
> ```
> ai-flume/
> ├── state-service/          # FastAPI attribution service
> │   ├── state_service/      # Python package
> │   └── requirements.txt
> ├── dashboard/              # Real-time usage dashboard (ACA)
> ├── infra/                  # Terraform (4 modules)
> │   ├── env/dev|uat|prod/
> │   └── modules/gateway|state_service|dashboard_aca|grafana_cloud/
> ├── docs/
> │   ├── PRD.md              # Product requirements
> │   ├── Terraform_Blueprint.md
> │   ├── CI_CD.md
> │   └── planning/
> ├── scripts/                # Bootstrap + init scripts
> ├── CLAUDE.md               # AI agent onboarding
> ├── package.json            # pnpm workspace (Prettier tooling)
> └── README.md
> ```
>
> ---
>
> ## Prerequisites
>
> - Azure CLI (`az login`)
> - - Terraform >= 1.14.0
>   - - Bash or PowerShell (for scripts)
>     - - pnpm (formatting tooling)
>      
>       - ---
>
> ## Quick start
>
> ### 1. Bootstrap Terraform state (one-time)
>
> Creates the shared resource group, storage account, and container for Terraform state.
>
> ```bash
> # Bash
> ./scripts/bootstrap.sh <GITHUB_ORG> <GITHUB_REPO> [SCOPE]
>
> # PowerShell
> .\scripts\bootstrap.ps1 -GITHUB_ORG <org> -GITHUB_REPO <repo> [-SCOPE <scope>]
> ```
>
> ### 2. Add GitHub secrets
>
> Add these secrets to each GitHub Environment (`dev`, `uat`, `prod`) under Settings → Environments → `<env>` → Environment secrets.
>
> | Secret | Description |
> |---|---|
> | `TF_BACKEND_RG` | Terraform state resource group |
> | `TF_BACKEND_SA` | Terraform state storage account |
> | `TF_BACKEND_CONTAINER` | Terraform state container |
> | `AZURE_CLIENT_ID` | OIDC app (from bootstrap) |
> | `AZURE_TENANT_ID` | Azure tenant ID |
> | `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
> | `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint URL |
> | `AZURE_OPENAI_API_KEY` | Azure OpenAI API key |
> | `AIGATEWAY_KEY` | Gateway auth key (from bootstrap) |
>
> ### 3. Terraform init
>
> ```bash
> ./infra/scripts/terraform-init.sh dev   # or uat, prod
> ```
>
> ### 4. Plan and apply
>
> ```bash
> cd infra/env/dev
> terraform plan
> terraform apply
> ```
>
> ---
>
> ## Formatting
>
> ```bash
> pnpm install
> pnpm check          # lint + terraform fmt check
> pnpm format         # apply Prettier
> ```
>
> ---
>
> ## Documentation
>
> - [PRD](docs/PRD.md) — product requirements and scope
> - - [Terraform Blueprint](docs/Terraform_Blueprint.md) — infrastructure design
>   - - [CI/CD Runbook](docs/CI_CD.md) — workflow behaviour, UAT toggle, smoke tests
>     - - [Azure OIDC Setup](docs/azure-oidc-setup.md) — GitHub Actions OIDC configuration
>       - - [Secrets Checklist](docs/secrets-checklist.md) — copy/paste setup for GitHub secrets
>        
>         - ---
>
> ## Ecosystem
>
> ai-flume is the AI data plane within the phoenixvc platform. It connects to:
>
> | Repo | Role |
> |---|---|
> | [`cockpit`](https://github.com/phoenixvc/cockpit) | Desktop ops tool — embeds the dashboard via webview, routes its own AI calls through ai-flume |
> | [`ai-gauge`](https://github.com/phoenixvc/ai-gauge) | Reads state-service attribution data to produce cost reports and budget alerts |
> | [`ai-cadence`](https://github.com/phoenixvc/ai-cadence) | Project tracker — its AI routing calls pass through ai-flume |
> | [`cognitive-mesh`](https://github.com/phoenixvc/cognitive-mesh) | Agent orchestration — all model calls route through ai-flume |
> | [`retort`](https://github.com/phoenixvc/retort) | Agent scaffold template — onboarded projects inherit ai-flume as their gateway |
> | [`org-meta`](https://github.com/phoenixvc/org-meta) | Org registry — documents ai-flume as shared infrastructure |
>
> ---
>
> ## Inspiration
>
> - [**mcowger/plexus**](https://github.com/mcowger/plexus) — unified AI gateway for multiple providers (OpenAI, Anthropic, Gemini). Same domain; worth studying for provider abstraction patterns. **⚠️ No licence file — study only, do not copy code directly. Consider reaching out to the author if deeper reuse is wanted.**
>
> - ---
>
> ## Name
>
> **ai-flume** — a flume is an engineered channel that directs flow precisely. In mining and water management, a flume carries material from source to destination with controlled pressure and speed. Here, ai-flume carries AI traffic — requests, tokens, spans — from all clients to the models and back, with full observability at every point. The name pairs intentionally with `cockpit` (which operates the controls) and sits alongside `ai-gauge` (which measures what flows through).
>
> Previously named `ai-gateway`. Renamed to reflect its evolution from a simple proxy into a full shared AI data plane.
> 
