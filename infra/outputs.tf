output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region"
  value       = azurerm_resource_group.main.location
}

output "n8n_url" {
  description = "URL to access n8n"
  value       = "https://${azurerm_container_app.n8n.ingress[0].fqdn}"
}

output "n8n_fqdn" {
  description = "FQDN of the n8n container app"
  value       = azurerm_container_app.n8n.ingress[0].fqdn
}

output "container_app_name" {
  description = "Name of the n8n container app"
  value       = azurerm_container_app.n8n.name
}

output "postgres_container_app_name" {
  description = "Name of the PostgreSQL container app"
  value       = azurerm_container_app.postgres.name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "container_app_environment_name" {
  description = "Name of the Container Apps environment"
  value       = azurerm_container_app_environment.main.name
}

output "n8n_encryption_key" {
  description = "n8n encryption key (sensitive)"
  value       = random_string.n8n_encryption_key.result
  sensitive   = true
}
