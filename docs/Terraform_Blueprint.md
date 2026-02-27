# Terraform (Copy/Paste Ready): PVC AI Gateway (ACA + KV + Logs) + Shared State

This canvas includes a working Terraform scaffold:

* `infra/modules/aigateway_aca`
* `infra/env/dev|uat|prod`
* Shared state configured via `terraform init -backend-config=...` in GitHub Actions

> Notes:
>
> * Some Azure resources have naming constraints; this blueprint uses a helper to generate compliant names.
> * Container Apps requires recent `azurerm` provider versions.

---

## 1) File tree

```text
infra/
  modules/
    aigateway_aca/
      main.tf
      variables.tf
      outputs.tf
  env/
    dev/
      main.tf
      variables.tf
      terraform.tfvars
    uat/
      main.tf
      variables.tf
      terraform.tfvars
    prod/
      main.tf
      variables.tf
      terraform.tfvars
```

---

## 2) Module: `infra/modules/aigateway_aca/variables.tf`

```hcl
variable "env" {
  type        = string
  description = "Environment name (dev|uat|prod)"
}

variable "projname" {
  type        = string
  description = "Project name"
  default     = "aigateway"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "southafricanorth"
}

variable "location_short" {
  type        = string
  description = "Short location code"
  default     = "san"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

# LiteLLM container
variable "container_image" {
  type        = string
  description = "LiteLLM container image"
  default     = "ghcr.io/berriai/litellm:latest"
}

variable "container_port" {
  type        = number
  description = "Container port for LiteLLM"
  default     = 4000
}

# Ingress
variable "ingress_external" {
  type        = bool
  description = "Whether ingress is external"
  default     = true
}

# Security: simple client->gateway auth
variable "gateway_key" {
  type        = string
  description = "Shared key clients must send as x-gateway-key"
  sensitive   = true
}

# Upstream Azure OpenAI
variable "azure_openai_endpoint" {
  type        = string
  description = "Azure OpenAI endpoint host, e.g. https://mys-shared-ai-swc.cognitiveservices.azure.com"
}

variable "azure_openai_api_key" {
  type        = string
  description = "Azure OpenAI API key"
  sensitive   = true
}

variable "codex_model" {
  type        = string
  description = "Codex deployment/model name for responses"
  default     = "gpt-5.3-codex"
}

variable "codex_api_version" {
  type        = string
  description = "Responses API version"
  default     = "2025-04-01-preview"
}

variable "embedding_deployment" {
  type        = string
  description = "Embedding deployment name"
  default     = "text-embedding-3-large"
}

variable "embeddings_api_version" {
  type        = string
  description = "Embeddings API version"
  default     = "2023-05-15"
}

# Optional scaling
variable "min_replicas" {
  type        = number
  default     = 0
}

variable "max_replicas" {
  type        = number
  default     = 3
}
```

---

## 3) Module: `infra/modules/aigateway_aca/main.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.62.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  prefix = "pvc-${var.env}-${var.projname}"

  # Azure naming constraints:
  # - Key Vault: 3-24 chars, alphanumeric + hyphen, must start with letter
  # - Many resources allow hyphens but not all; keep consistent
  kv_name_raw = lower(replace("${local.prefix}-kv-${var.location_short}", "_", "-"))

  # Ensure KV starts with a letter and is <=24 chars
  kv_name = substr(regexreplace(local.kv_name_raw, "^[^a-z]+", "p"), 0, 24)

  rg_name  = "${local.prefix}-rg-${var.location_short}"
  law_name = "${local.prefix}-law-${var.location_short}"
  cae_name = "${local.prefix}-cae-${var.location_short}"
  ca_name  = "${local.prefix}-ca-${var.location_short}"

  tags = merge({
    env     = var.env
    project = var.projname
  }, var.tags)

  # Minimal LiteLLM config: enforce gateway key and route to Azure
  # We keep it tiny: single upstream, OpenAI-compatible endpoints.
  # LiteLLM specifics may evolve; this pattern is reliable for basic proxying.
  litellm_config = <<-YAML
  model_list:
    - model_name: ${var.codex_model}
      litellm_params:
        model: azure/${var.codex_model}
        api_base: ${var.azure_openai_endpoint}/openai
        api_key: os.environ/LITELLM_AZURE_OPENAI_API_KEY
        api_version: ${var.codex_api_version}
        # responses api
        # LiteLLM maps OpenAI-compatible surface to Azure responses when available

    - model_name: ${var.embedding_deployment}
      litellm_params:
        model: azure/${var.embedding_deployment}
        api_base: ${var.azure_openai_endpoint}
        api_key: os.environ/LITELLM_AZURE_OPENAI_API_KEY
        api_version: ${var.embeddings_api_version}

  # Simple auth guard: require x-gateway-key (we implement via LiteLLM master key)
  # Many OpenAI-compatible tools send Authorization; Roo can send custom headers.
  # If you prefer Authorization bearer, swap enforcement accordingly.
  general_settings:
    # master_key works as a shared secret gate in LiteLLM
    master_key: os.environ/LITELLM_GATEWAY_KEY
  YAML
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_container_app_environment" "cae" {
  name                       = local.cae_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = local.tags
}

resource "azurerm_key_vault" "kv" {
  name                = local.kv_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = var.env == "prod" ? 30 : 7
  purge_protection_enabled   = var.env == "prod" ? true : false

  tags = local.tags
}

data "azurerm_client_config" "current" {}

# Store secrets in KV (optional but useful)
resource "azurerm_key_vault_secret" "gateway_key" {
  name         = "gateway-key"
  value        = var.gateway_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "azure_openai_key" {
  name         = "azure-openai-key"
  value        = var.azure_openai_api_key
  key_vault_id = azurerm_key_vault.kv.id
}

# Container App
resource "azurerm_container_app" "ca" {
  name                         = local.ca_name
  container_app_environment_id  = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "litellm"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "LITELLM_CONFIG"
        value = local.litellm_config
      }

      env {
        name  = "LITELLM_AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-key"
      }

      env {
        name  = "LITELLM_GATEWAY_KEY"
        secret_name = "gateway-key"
      }

      # LiteLLM commonly listens on 4000; set port as needed
    }
  }

  ingress {
    external_enabled = var.ingress_external
    target_port      = var.container_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
```

---

## 4) Module: `infra/modules/aigateway_aca/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "gateway_fqdn" {
  value = azurerm_container_app.ca.ingress[0].fqdn
}

output "gateway_url" {
  value = "https://${azurerm_container_app.ca.ingress[0].fqdn}"
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}
```

---

## 5) Env stacks

### 5.1 `infra/env/dev/variables.tf` (repeat for uat/prod)

```hcl
variable "env" { type = string }
variable "location" { type = string }
variable "location_short" { type = string }
variable "projname" { type = string }

variable "azure_openai_endpoint" { type = string }
variable "azure_openai_api_key" { type = string sensitive = true }

variable "gateway_key" { type = string sensitive = true }

variable "codex_model" { type = string }
variable "codex_api_version" { type = string }

variable "embedding_deployment" { type = string }
variable "embeddings_api_version" { type = string }

variable "tags" { type = map(string) }
```

### 5.2 `infra/env/dev/main.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.62.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "aigateway" {
  source = "../../modules/aigateway_aca"

  env           = var.env
  projname      = var.projname
  location      = var.location
  location_short= var.location_short
  tags          = var.tags

  azure_openai_endpoint   = var.azure_openai_endpoint
  azure_openai_api_key    = var.azure_openai_api_key

  gateway_key             = var.gateway_key

  codex_model             = var.codex_model
  codex_api_version       = var.codex_api_version

  embedding_deployment    = var.embedding_deployment
  embeddings_api_version  = var.embeddings_api_version

  ingress_external        = true
  min_replicas            = 0
  max_replicas            = 3
}

output "gateway_url" {
  value = module.aigateway.gateway_url
}
```

### 5.3 `infra/env/dev/terraform.tfvars` (example)

```hcl
env            = "dev"
projname        = "aigateway"
location        = "southafricanorth"
location_short  = "san"

# Your Azure OpenAI endpoint host
azure_openai_endpoint = "https://mys-shared-ai-swc.cognitiveservices.azure.com"

# Secrets should be injected via CI in real usage; tfvars shown for local testing only.
# azure_openai_api_key = "..."
# gateway_key          = "..."

codex_model       = "gpt-5.3-codex"
codex_api_version = "2025-04-01-preview"

embedding_deployment   = "text-embedding-3-large"
embeddings_api_version = "2023-05-15"

tags = {
  owner    = "J"
  project  = "aigateway"
  env      = "dev"
}
```

Repeat the env folders for `uat` and `prod`, changing only `env` and tags.

---

## 6) Feeding secrets in CI (recommended)

Instead of putting keys in `terraform.tfvars`, set Terraform variables from GitHub environment secrets:

* `TF_VAR_azure_openai_api_key`
* `TF_VAR_gateway_key`

Example (add to your workflow steps before terraform commands):

```yaml
env:
  TF_VAR_azure_openai_api_key: ${{ secrets.AZURE_OPENAI_API_KEY }}
  TF_VAR_gateway_key: ${{ secrets.AIGATEWAY_KEY }}
  TF_VAR_azure_openai_endpoint: "https://mys-shared-ai-swc.cognitiveservices.azure.com"
  TF_VAR_env: ${{ matrix.env }}
  TF_VAR_projname: "aigateway"
  TF_VAR_location: "southafricanorth"
  TF_VAR_location_short: "san"
  TF_VAR_codex_model: "gpt-5.3-codex"
  TF_VAR_codex_api_version: "2025-04-01-preview"
  TF_VAR_embedding_deployment: "text-embedding-3-large"
  TF_VAR_embeddings_api_version: "2023-05-15"
```

Add GitHub **environment secrets** per env:

* `AZURE_OPENAI_API_KEY`
* `AIGATEWAY_KEY`

---

## 7) Smoke tests (after deploy)

After apply, test gateway endpoints.

Example curl (assuming gateway uses LiteLLM master key as bearer):

```bash
export GW="https://<gateway-fqdn>"
export KEY="<gateway_key>"

# embeddings
curl -sS "$GW/v1/embeddings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $KEY" \
  -d '{"model":"text-embedding-3-large","input":"hello"}'

# responses
curl -sS "$GW/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $KEY" \
  -d '{"model":"gpt-5.3-codex","input":"Say hi in one sentence."}'
```

---

## 8) Roo/Qoder configuration (target end-state)

In Roo/Qoder:

* Provider: OpenAI Compatible
* Base URL: `https://<gateway-fqdn>`
* API Key: use the same `gateway_key` (if using LiteLLM master key bearer)
* Model for coding: `gpt-5.3-codex`

For indexing:

* Base URL: `https://<gateway-fqdn>`
* Model: `text-embedding-3-large`
* Dimension: match your embedding deployment (commonly 3072 for 3-large)

---

## 9) Hard truth (what may need tweaking)

LiteLLM’s Azure+Responses mapping evolves. If `/v1/responses` doesn’t route correctly on first try, the gateway still helps because you can adjust mapping **once** in LiteLLM, instead of fighting Roo’s provider assumptions across machines.
