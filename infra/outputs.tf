# Terraform outputs for n8n deployment
# Provides resource names, URLs, and configuration for post-provision hooks

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "n8n_container_app_name" {
  description = "The name of the n8n Container App"
  value       = azurerm_container_app.n8n.name
}

output "n8n_url" {
  description = "The URL to access n8n"
  value       = "https://${azurerm_container_app.n8n.ingress[0].fqdn}"
}

output "n8n_fqdn" {
  description = "The FQDN of the n8n Container App"
  value       = azurerm_container_app.n8n.ingress[0].fqdn
}

output "postgres_server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_container_app_name" {
  description = "Alias for postgres_server_name (for compatibility)"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_fqdn" {
  description = "The FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "The name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "n8n_encryption_key" {
  description = "The n8n encryption key (save securely)"
  value       = random_password.n8n_encryption_key.result
  sensitive   = true
}

output "n8n_basic_auth_user" {
  description = "The n8n basic authentication username"
  value       = var.n8n_basic_auth_user
}
