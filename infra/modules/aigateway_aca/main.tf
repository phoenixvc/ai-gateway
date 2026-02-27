terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0, < 4.0.0"
    }
  }
}

locals {
  prefix = "pvc-${var.env}-${var.projname}"

  # Azure naming constraints:
  # - Key Vault: 3-24 chars, alphanumeric + hyphen, must start with letter
  # - Many resources allow hyphens but not all; keep consistent
  kv_name_raw = lower(replace("${local.prefix}-kv-${var.location_short}", "_", "-"))

  # Ensure KV starts with a letter and is <=24 chars
  kv_name = substr(try(replace(local.kv_name_raw, regex("^[^a-z]+", local.kv_name_raw), "p"), local.kv_name_raw), 0, 24)

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

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

data "azurerm_client_config" "current" {}


resource "azurerm_key_vault_access_policy" "terraform_client" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

# Store secrets in KV (optional but useful)
resource "azurerm_key_vault_secret" "gateway_key" {
  name            = "gateway-key"
  value           = var.gateway_key
  key_vault_id    = azurerm_key_vault.kv.id
  expiration_date = var.secrets_expiration_date

  depends_on = [azurerm_key_vault_access_policy.terraform_client]
}

resource "azurerm_key_vault_secret" "azure_openai_key" {
  name            = "azure-openai-key"
  value           = var.azure_openai_api_key
  key_vault_id    = azurerm_key_vault.kv.id
  expiration_date = var.secrets_expiration_date

  depends_on = [azurerm_key_vault_access_policy.terraform_client]
}

resource "azurerm_user_assigned_identity" "ca" {
  name                = "${local.ca_name}-id"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_key_vault_access_policy" "container_app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.ca.principal_id

  secret_permissions = ["Get", "List"]
}

# Container App
resource "azurerm_container_app" "ca" {
  lifecycle {
    precondition {
      condition     = var.min_replicas <= var.max_replicas
      error_message = "min_replicas (${var.min_replicas}) must not exceed max_replicas (${var.max_replicas})."
    }
  }

  depends_on = [azurerm_key_vault_access_policy.container_app]

  name                         = local.ca_name
  container_app_environment_id  = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ca.id]
  }

  secret {
    name                  = "azure-openai-key"
    key_vault_secret_id   = azurerm_key_vault_secret.azure_openai_key.versionless_id
    identity              = azurerm_user_assigned_identity.ca.id
  }

  secret {
    name                  = "gateway-key"
    key_vault_secret_id   = azurerm_key_vault_secret.gateway_key.versionless_id
    identity              = azurerm_user_assigned_identity.ca.id
  }

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
        name        = "LITELLM_AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-key"
      }

      env {
        name        = "LITELLM_GATEWAY_KEY"
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
