output "tfstate_rg" {
  value = azurerm_resource_group.rg.name
}

output "tfstate_storage" {
  value = azurerm_storage_account.st.name
}

output "tfstate_container" {
  value = azurerm_storage_container.ct.name
}
