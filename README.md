# ai-gateway

OpenAI-compatible AI Gateway (LiteLLM) on Azure Container Apps. Routes `/v1/responses` and `/v1/embeddings` to Azure OpenAI.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az login`)
- [Terraform](https://www.terraform.io/downloads) >= 1.14.0
- Bash or PowerShell (for scripts)

## Quick Start

### 1. Bootstrap Terraform state (one-time)

Creates the shared resource group, storage account, and container for Terraform state.

**Bash:**

```bash
./scripts/bootstrap.sh <GITHUB_ORG> <GITHUB_REPO> [SCOPE]
```

**PowerShell:**

```powershell
.\scripts\bootstrap.ps1 -GITHUB_ORG <org> -GITHUB_REPO <repo> [-SCOPE <scope>]
```

### 2. Add GitHub secrets

Add these secrets to each GitHub **Environment** (dev, uat, prod): **Settings → Environments → &lt;env&gt; → Environment secrets**.

| Secret                  | Description                       | Example                                       |
| ----------------------- | --------------------------------- | --------------------------------------------- |
| **Infrastructure**      |                                   |                                               |
| `TF_BACKEND_RG`         | Terraform state resource group    | `pvc-shared-tfstate-rg-san`                   |
| `TF_BACKEND_SA`         | Terraform state storage account   | `pvctfstatexxxxxxxx`                          |
| `TF_BACKEND_CONTAINER`  | Terraform state container         | `tfstate`                                     |
| `AZURE_CLIENT_ID`       | OIDC app (from bootstrap)         | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`        |
| `AZURE_TENANT_ID`       | Azure tenant ID                   | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`        |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID             | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`        |
| **Application**         |                                   |                                               |
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint URL         | `https://mys-shared-ai-san.openai.azure.com/` |
| `AZURE_OPENAI_API_KEY`  | Azure OpenAI API key              | Your Azure OpenAI key                         |
| `AIGATEWAY_KEY`         | Gateway auth key (from bootstrap) | Base64 string from bootstrap output           |

Bootstrap prints these values. For local runs, copy `infra/.env.local.example` to `infra/.env.local` with the infrastructure values.

> **Key Vault firewall:** Deployments from GitHub Actions require Key Vault to allow public network access. The Terraform module defaults `key_vault_network_default_action` to `Allow` for CI. If you see `ForbiddenByFirewall`, ensure the `fix/key-vault-network-acls` changes are merged and applied.

### 3. Terraform init

**Bash:**

```bash
./infra/scripts/terraform-init.sh dev   # or uat, prod
```

**PowerShell:**

```powershell
.\infra\scripts\terraform-init.ps1 -Env dev   # or uat, prod
```

Valid environments: `dev`, `uat`, `prod`.

### 4. Plan and apply

```bash
cd infra/env/dev
terraform plan
terraform apply
```

## Environments

| Env  | Purpose         |
| ---- | --------------- |
| dev  | Development     |
| uat  | User acceptance |
| prod | Production      |

## CI/CD

- CI/CD behavior, environment promotion rules, and smoke-test diagnostics are documented in [docs/CI_CD.md](docs/CI_CD.md).

## Documentation

- [PRD](docs/PRD.md) – Product requirements
- [Terraform Blueprint](docs/Terraform_Blueprint.md) – Infrastructure design
- [CI/CD Runbook](docs/CI_CD.md) – workflow behavior, UAT toggle, smoke tests
- [Azure OIDC Setup](docs/AZURE_OIDC_SETUP.md) – GitHub Actions OIDC configuration
- [Secrets Checklist](docs/SECRETS.md) – Copy/paste setup for GitHub environment secrets
