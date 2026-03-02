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
