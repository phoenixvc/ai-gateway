terraform {
  required_version = ">= 1.14.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }

  # Reuses the same Azure Storage backend as the ACA environments; state is
  # stored under a separate key so it does not interfere with Azure resources.
  backend "azurerm" {}
}

# Configure the Grafana provider with a Cloud access policy token.
# Generate this token at https://grafana.com/profile/api-keys with at least
# the following scopes: stacks:read, stacks:write,
# stack-service-accounts:read, stack-service-accounts:write.
provider "grafana" {
  cloud_access_policy_token = var.grafana_cloud_access_policy_token
}

module "grafana_cloud" {
  source = "../modules/grafana_cloud"

  stack_name  = var.stack_name
  stack_slug  = var.stack_slug
  region_slug = var.region_slug
}

output "stack_url" {
  description = "Grafana Cloud stack URL. Set as the GRAFANA_URL GitHub Actions secret."
  value       = module.grafana_cloud.stack_url
}

output "prometheus_url" {
  description = "Prometheus endpoint URL for LiteLLM /metrics scraping or Alloy remote-write configuration."
  value       = module.grafana_cloud.prometheus_url
}

output "github_actions_token" {
  description = "Set this value as the GRAFANA_SA_TOKEN GitHub Actions secret to enable dashboard deployments."
  value       = module.grafana_cloud.github_actions_token
  sensitive   = true
}
