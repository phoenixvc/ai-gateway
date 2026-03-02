output "dashboard_fqdn" {
  description = "Fully-qualified domain name of the dashboard Container App."
  value       = azurerm_container_app.dashboard.ingress[0].fqdn
}

output "dashboard_url" {
  description = "Public HTTPS URL of the dashboard."
  value       = "https://${azurerm_container_app.dashboard.ingress[0].fqdn}"
}
