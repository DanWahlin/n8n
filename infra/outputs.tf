output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "n8n_url" {
  description = "URL to access n8n"
  value       = "https://${azurerm_container_app.n8n.ingress[0].fqdn}"
}

output "n8n_fqdn" {
  description = "Fully qualified domain name of n8n"
  value       = azurerm_container_app.n8n.ingress[0].fqdn
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "container_app_identity_principal_id" {
  description = "Principal ID of the Container App managed identity"
  value       = azurerm_user_assigned_identity.container_app.principal_id
}

output "n8n_encryption_key" {
  description = "n8n encryption key (sensitive)"
  value       = random_string.encryption_key.result
  sensitive   = true
}
