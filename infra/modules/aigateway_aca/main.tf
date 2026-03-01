terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.62.0"
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

  # Redis hostname: resolved when Redis is enabled, empty string otherwise.
  # try() avoids a plan-time error when enable_redis_cache = false (count = 0).
  redis_host = try(azurerm_redis_cache.cache[0].hostname, "")

  # LiteLLM proxy configuration.
  # Features enabled here:
  #   - JSON structured logging → Log Analytics Workspace via Container Apps stdout
  #   - Prometheus /metrics endpoint (built-in, no extra infra)
  #   - Langfuse tracing (when both langfuse_public_key and langfuse_secret_key are provided)
  #   - Redis semantic caching (when enable_redis_cache = true)
  #   - Global budget / rate limits (when set above 0)
  litellm_config = <<-YAML
  model_list:
    - model_name: ${var.codex_model}
      litellm_params:
        model: azure/${var.codex_model}
        api_base: ${var.azure_openai_endpoint}
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
      model_info:
        mode: embedding

  # Structured logging: JSON lines to stdout, streamed by Container Apps into
  # the Log Analytics Workspace. Query with:
  #   ContainerAppConsoleLogs_CL
  #   | where ContainerName_s == "litellm"
  #   | project TimeGenerated, Log_s
  litellm_settings:
    json_logs: true
    # Prometheus /metrics: token usage, latency and error rate at <gateway>/metrics
    success_callback:
      - prometheus
  %{if var.langfuse_public_key != "" && var.langfuse_secret_key != ""~}
      - langfuse
  %{endif}
    failure_callback:
      - prometheus
  %{if var.langfuse_public_key != "" && var.langfuse_secret_key != ""~}
      - langfuse
  %{endif}
  %{if var.enable_redis_cache~}
    # Redis: deduplicate identical requests to reduce Azure OpenAI token spend
    cache: true
    cache_params:
      type: redis
      host: ${local.redis_host}
      port: 6380
      password: os.environ/REDIS_PASSWORD
      ssl: true
  %{endif~}
  %{if var.max_budget > 0~}
    max_budget: ${var.max_budget}
  %{endif~}
  %{if var.budget_duration != ""~}
    budget_duration: "${var.budget_duration}"
  %{endif~}
  %{if var.rpm_limit > 0~}
    rpm_limit: ${var.rpm_limit}
  %{endif~}
  %{if var.tpm_limit > 0~}
    tpm_limit: ${var.tpm_limit}
  %{endif~}

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
    default_action = var.key_vault_network_default_action
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

# Azure Cache for Redis (optional — set enable_redis_cache = true to provision)
resource "azurerm_redis_cache" "cache" {
  count               = var.enable_redis_cache ? 1 : 0
  name                = "${local.prefix}-redis-${var.location_short}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = var.redis_cache_capacity
  family              = "C"
  sku_name            = "Basic"
  minimum_tls_version = "1.2"
  tags                = local.tags
}

resource "azurerm_key_vault_secret" "redis_password" {
  count           = var.enable_redis_cache ? 1 : 0
  name            = "redis-password"
  value           = azurerm_redis_cache.cache[0].primary_access_key
  key_vault_id    = azurerm_key_vault.kv.id
  expiration_date = var.secrets_expiration_date

  depends_on = [azurerm_key_vault_access_policy.terraform_client]
}

# Langfuse observability secrets (optional — only created when keys are supplied)
resource "azurerm_key_vault_secret" "langfuse_public_key" {
  count           = var.langfuse_public_key != "" && var.langfuse_secret_key != "" ? 1 : 0
  name            = "langfuse-public-key"
  value           = var.langfuse_public_key
  key_vault_id    = azurerm_key_vault.kv.id
  expiration_date = var.secrets_expiration_date

  depends_on = [azurerm_key_vault_access_policy.terraform_client]
}

resource "azurerm_key_vault_secret" "langfuse_secret_key" {
  count           = var.langfuse_public_key != "" && var.langfuse_secret_key != "" ? 1 : 0
  name            = "langfuse-secret-key"
  value           = var.langfuse_secret_key
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
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ca.id]
  }

  secret {
    name                = "azure-openai-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_key.versionless_id
    identity            = azurerm_user_assigned_identity.ca.id
  }

  secret {
    name                = "gateway-key"
    key_vault_secret_id = azurerm_key_vault_secret.gateway_key.versionless_id
    identity            = azurerm_user_assigned_identity.ca.id
  }

  dynamic "secret" {
    for_each = var.enable_redis_cache ? [1] : []
    content {
      name                = "redis-password"
      key_vault_secret_id = azurerm_key_vault_secret.redis_password[0].versionless_id
      identity            = azurerm_user_assigned_identity.ca.id
    }
  }

  dynamic "secret" {
    for_each = var.langfuse_public_key != "" && var.langfuse_secret_key != "" ? [1] : []
    content {
      name                = "langfuse-public-key"
      key_vault_secret_id = azurerm_key_vault_secret.langfuse_public_key[0].versionless_id
      identity            = azurerm_user_assigned_identity.ca.id
    }
  }

  dynamic "secret" {
    for_each = var.langfuse_public_key != "" && var.langfuse_secret_key != "" ? [1] : []
    content {
      name                = "langfuse-secret-key"
      key_vault_secret_id = azurerm_key_vault_secret.langfuse_secret_key[0].versionless_id
      identity            = azurerm_user_assigned_identity.ca.id
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "litellm"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      # Write config content to a temp file and start LiteLLM with --config.
      # LITELLM_CONFIG env var is not read by LiteLLM; a file path via --config is required.
      command = [
        "/bin/sh",
        "-c",
        "printf '%s' \"$LITELLM_CONFIG_CONTENT\" > /tmp/proxy_config.yaml || { echo 'ERROR: failed to write LiteLLM config to /tmp/proxy_config.yaml' >&2; exit 1; }; exec litellm --config /tmp/proxy_config.yaml --port ${var.container_port}"
      ]

      env {
        name  = "LITELLM_CONFIG_CONTENT"
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

      dynamic "env" {
        for_each = var.enable_redis_cache ? [1] : []
        content {
          name        = "REDIS_PASSWORD"
          secret_name = "redis-password"
        }
      }

      dynamic "env" {
        for_each = var.langfuse_public_key != "" && var.langfuse_secret_key != "" ? [1] : []
        content {
          name        = "LANGFUSE_PUBLIC_KEY"
          secret_name = "langfuse-public-key"
        }
      }

      dynamic "env" {
        for_each = var.langfuse_public_key != "" && var.langfuse_secret_key != "" ? [1] : []
        content {
          name        = "LANGFUSE_SECRET_KEY"
          secret_name = "langfuse-secret-key"
        }
      }

      dynamic "env" {
        for_each = var.langfuse_host != "" ? [var.langfuse_host] : []
        content {
          name  = "LANGFUSE_HOST"
          value = env.value
        }
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
