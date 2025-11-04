# Terraform Outputs for n8n on Azure
# This file exposes important values after deployment

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "n8n_container_app_name" {
  description = "Name of the n8n Container App"
  value       = azurerm_container_app.n8n.name
}

output "n8n_url" {
  description = "URL to access n8n"
  value       = "https://${azurerm_container_app.n8n.ingress[0].fqdn}"
}

output "n8n_fqdn" {
  description = "Fully qualified domain name of the n8n Container App"
  value       = azurerm_container_app.n8n.ingress[0].fqdn
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_container_app_name" {
  description = "Name of the PostgreSQL Flexible Server (alias for compatibility)"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "n8n_encryption_key" {
  description = "n8n encryption key (CRITICAL: Save this securely!)"
  value       = random_password.n8n_encryption_key.result
  sensitive   = true
}

output "n8n_basic_auth_user" {
  description = "n8n basic authentication username"
  value       = var.n8n_basic_auth_user
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}
