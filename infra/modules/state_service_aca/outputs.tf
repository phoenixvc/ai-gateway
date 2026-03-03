output "state_service_fqdn" {
  description = "State service Container App FQDN"
  value       = azurerm_container_app.state_service.ingress[0].fqdn
}

output "state_service_url" {
  description = "Public HTTPS URL of the state service"
  value       = "https://${azurerm_container_app.state_service.ingress[0].fqdn}"
}
