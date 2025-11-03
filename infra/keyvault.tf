# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  enable_rbac_authorization = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = {
    Environment = var.environment_name
    Project     = var.project_name
  }
}

# Role assignment for Container App managed identity to read secrets
resource "azurerm_role_assignment" "container_app_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

# Role assignment for current user to manage secrets (for post-provision hook)
resource "azurerm_role_assignment" "current_user_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
