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

output "redis_hostname" {
  value       = try(azurerm_redis_cache.cache[0].hostname, null)
  description = "Azure Cache for Redis hostname (null when enable_redis_cache = false)."
}

output "redis_primary_access_key" {
  value       = try(azurerm_redis_cache.cache[0].primary_access_key, null)
  description = "Azure Cache for Redis primary access key (null when enable_redis_cache = false)."
  sensitive   = true
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment — used by sibling modules (e.g. dashboard_aca) to deploy into the same environment."
  value       = azurerm_container_app_environment.cae.id
}

output "application_insights_name" {
  description = "Application Insights resource name. Retrieve connection string from Key Vault secret 'appinsights-connection-string'."
  value       = azurerm_application_insights.ai.name
}
