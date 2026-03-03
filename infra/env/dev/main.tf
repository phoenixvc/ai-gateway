terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.62.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

module "aigateway" {
  source = "../../modules/aigateway_aca"

  env            = var.env
  projname       = var.projname
  location       = var.location
  location_short = var.location_short
  tags           = var.tags

  container_image = var.container_image

  azure_openai_endpoint = var.azure_openai_endpoint
  azure_openai_api_key  = var.azure_openai_api_key

  azure_openai_embedding_endpoint = var.azure_openai_embedding_endpoint
  azure_openai_embedding_api_key  = var.azure_openai_embedding_api_key

  gateway_key = var.gateway_key

  codex_model       = var.codex_model
  codex_api_version = var.codex_api_version

  embedding_deployment   = var.embedding_deployment
  embeddings_api_version = var.embeddings_api_version

  ingress_external        = var.ingress_external
  min_replicas            = var.min_replicas
  max_replicas            = var.max_replicas
  secrets_expiration_date = var.secrets_expiration_date

  langfuse_public_key = var.langfuse_public_key
  langfuse_secret_key = var.langfuse_secret_key
  langfuse_host       = var.langfuse_host

  enable_redis_cache   = var.enable_redis_cache
  redis_cache_sku      = var.redis_cache_sku
  redis_cache_capacity = var.redis_cache_capacity

  max_budget      = var.max_budget
  budget_duration = var.budget_duration
  rpm_limit       = var.rpm_limit
  tpm_limit       = var.tpm_limit
}

module "state_service" {
  count  = var.state_service_container_image == "" ? 0 : 1
  source = "../../modules/state_service_aca"

  env            = var.env
  projname       = var.projname
  location_short = var.location_short
  tags           = var.tags

  container_app_environment_id = module.aigateway.container_app_environment_id
  resource_group_name          = module.aigateway.resource_group_name
  container_image              = var.state_service_container_image
  external_enabled             = var.state_service_external_enabled
  redis_url                    = var.enable_redis_cache ? format("rediss://:%s@%s:6380/0", module.aigateway.redis_primary_access_key, module.aigateway.redis_hostname) : ""
  state_service_shared_token   = var.state_service_shared_token
}

module "dashboard" {
  source = "../../modules/dashboard_aca"

  env            = var.env
  projname       = var.projname
  location_short = var.location_short
  tags           = var.tags

  container_app_environment_id = module.aigateway.container_app_environment_id
  resource_group_name          = module.aigateway.resource_group_name
  container_image              = var.dashboard_container_image
  gateway_url                  = module.aigateway.gateway_url
  grafana_url                  = var.grafana_url
  state_service_url            = var.state_service_container_image == "" ? "" : module.state_service[0].state_service_url
  state_service_shared_token   = var.state_service_shared_token
}

output "gateway_url" {
  value = module.aigateway.gateway_url
}

output "dashboard_url" {
  description = "Public HTTPS URL of the gateway dashboard Container App."
  value = module.dashboard.dashboard_url
}

output "state_service_url" {
  description = "Public HTTPS URL of the shared state service (null when disabled)."
  value       = var.state_service_container_image == "" ? null : module.state_service[0].state_service_url
}
