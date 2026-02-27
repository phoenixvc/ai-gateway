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

### 2. Configure backend

Copy `infra/.env.local.example` to `infra/.env.local` and fill in values from the bootstrap output:

```
TF_BACKEND_RG=<resource-group-name>
TF_BACKEND_SA=<storage-account-name>
TF_BACKEND_CONTAINER=tfstate
```

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

| Env  | Purpose        |
|------|----------------|
| dev  | Development    |
| uat  | User acceptance|
| prod | Production     |

## Documentation

- [PRD](docs/PRD.md) – Product requirements
- [Terraform Blueprint](docs/Terraform_Blueprint.md) – Infrastructure design
- [Azure OIDC Setup](docs/AZURE_OIDC_SETUP.md) – GitHub Actions OIDC configuration
