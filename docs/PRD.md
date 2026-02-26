# PRD: PVC AI Gateway (LiteLLM) on Azure

## 0) Context

You want Roo/Qoder (running on a laptop over public internet) to work with:

*   **Azure Codex** via the **Responses API** (not Chat Completions)
*   **Azure embeddings** for codebase indexing

Roo/Qoder currently struggles with Azure model/operation mismatches. A gateway normalizes the surface to **OpenAI-compatible** endpoints and handles Azure-specific routing.

## 1) Goals

1.  Provide a **single, stable OpenAI-compatible base URL** per environment.
2.  Support:
    *   `POST /v1/responses` routed to Azure **Responses** endpoint for configurable model (default: `gpt-5.3-codex`).
    *   `POST /v1/embeddings` routed to Azure embeddings deployment.
3.  Enable **multiple environments** (dev/uat/prod) and **multiple downstream projects**.
4.  Infrastructure managed with **Terraform**.
5.  CI/CD via **GitHub Actions** using **Azure OIDC** (no long-lived secrets).
6.  “Get it working” first; hardening follows.

## 2) Non-goals (v1)

*   Private-only networking end-to-end (phase 2)
*   Fine-grained org-wide chargeback and per-user quotas (phase 2)
*   Complex policy engine/redaction pipeline (phase 2)

## 3) Environments

*   `dev`
*   `uat`
*   `prod`

Each env is independently deployable.

## 4) Naming convention

Use: `pvc-{env}-{projname}-{resourcetype}-{location}`

*   `{projname}` = `aigateway`
*   `{location}` default `san` (southafricanorth)

Examples:

*   Resource group: `pvc-dev-aigateway-rg-san`
*   Log Analytics: `pvc-dev-aigateway-law-san`
*   Container Apps env: `pvc-dev-aigateway-cae-san`
*   Container App: `pvc-dev-aigateway-ca-san`
*   Key Vault: `pvc-dev-aigateway-kv-san`
*   Storage (tfstate): `pvc-dev-aigateway-st-san`
*   App Insights (optional): `pvc-dev-aigateway-ai-san`

## 5) Users / Personas

*   **You (developer)** using Roo/Qoder from a laptop over the public internet.
*   Later: CI agents, teammates, other internal tools.

## 6) Functional requirements

### FR1 — OpenAI-compatible surface

Gateway must expose:

*   `POST /v1/responses`
*   `POST /v1/embeddings`

### FR2 — Azure routing

*   `/v1/responses` → Azure `.../openai/responses?api-version=<var>` using `<model_var>`
*   `/v1/embeddings` → Azure `.../openai/deployments/<embed>/embeddings?api-version=<var>`

### FR3 — Auth (client → gateway)

*   Simple shared secret header (fastest): `x-gateway-key: <secret>` or `Authorization: Bearer <secret>` (LiteLLM standard).
*   Reject requests without the header.

### FR4 — Secret management (gateway → Azure)

*   Store Azure API keys in **Key Vault**.
*   Inject into Container App as secrets/env vars.

### FR5 — Rate limiting and retries (minimum viable)

*   Basic rate limit to prevent indexing storms.
*   Retry on transient 429/5xx with bounded backoff.

### FR6 — Multi-env isolation

*   Each env has its own gateway URL and secrets.

## 7) Non-functional requirements

### NFR1 — Reliability

*   Target 99% for v1 (it’s a dev tool, but should not be flaky).

### NFR2 — Security

*   No secrets in repo.
*   Keys stored in Key Vault.
*   Gateway enforces client auth header.
*   Minimal logging of request bodies (avoid storing source code prompts).

### NFR3 — Observability

*   Central logging in Log Analytics.
*   Track: request counts, latency, 4xx/5xx, 429, upstream failures.

### NFR4 — Cost control

*   Scale-to-zero or low minimum scale.
*   Optional concurrency limits.

## 8) Architecture

### 8.1 Platform choice

**Azure Container Apps (ACA)**

*   Low ops
*   Good revision/rollback
*   Built-in scaling

### 8.2 Ingress choice (recommended)

**Phase 1 (Get it working): External ingress**

*   Required because client is laptop on public internet.
*   Mitigate with:
    *   Gateway auth header
    *   Optional IP allowlist (if your egress IP is stable)

**Phase 2 (Harden):**

*   Front Door + WAF, or private ingress/VNET if you move clients inside Azure.

### 8.3 Components per env

*   Resource group
*   Log Analytics workspace
*   Container Apps Environment
*   Container App (LiteLLM)
*   Key Vault
*   Storage Account for Terraform state (or shared central tfstate)

## 9) Deployment and release

*   **Repo Structure**:
    *   `docs/` - Documentation.
    *   `infra/`
        *   `modules/aigateway_aca` - Core Terraform module.
        *   `env/dev|uat|prod` - Environment-specific configurations.
    *   `.github/workflows/` - CI/CD pipelines.
    *   `scripts/` - Helper scripts (bootstrap).

*   **Phase 0: Bootstrap**
    *   Script to create Azure Storage Account for Terraform state backend.
    *   Script to configure Azure OIDC (App Registration, Service Principal, Federated Credentials) for GitHub Actions.

*   **Phase 1: Terraform & CI/CD**
    *   Terraform defines infra.
    *   GitHub Actions deploys using Azure OIDC.
    *   Dev auto-apply on merge; UAT/Prod gated with environment approvals.

## 10) Acceptance criteria

1.  Roo/Qoder can use gateway for coding with configured model (default `gpt-5.3-codex`) without `chatCompletion operation does not work`.
2.  Codebase indexing completes using embeddings through the gateway.
3.  Dev/UAT/Prod are reproducible via Terraform + Actions.
4.  No secrets committed.

## 11) Risks & mitigations

*   **Public ingress risk** → auth header + (optional) IP allowlist + minimal logs.
*   **Azure API-version drift** → pin versions in config, add smoke tests in pipeline.
*   **Roo endpoint expectations** → keep gateway strictly OpenAI-compatible.

## 12) Milestones

*   M0: Repo setup, Bootstrap scripts (OIDC, State Backend).
*   M1: Dev env deployed; smoke tests pass; Roo works.
*   M2: UAT + Prod; environment approvals.
*   M3: Hardening (Front Door/WAF, Entra auth).
