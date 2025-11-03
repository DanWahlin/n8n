# Random suffix for unique resource names
resource "random_string" "resource_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Generate n8n encryption key
resource "random_string" "n8n_encryption_key" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment_name}-${random_string.resource_suffix.result}"
  location = var.location

  tags = {
    environment = var.environment_name
    application = "n8n"
    azd-env-name = var.environment_name
  }
}

# Log Analytics Workspace for Container Apps monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.environment_name}-${random_string.resource_suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment_name
    application = "n8n"
  }
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.environment_name}-${random_string.resource_suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    environment = var.environment_name
    application = "n8n"
  }
}

# PostgreSQL Container App for n8n database
resource "azurerm_container_app" "postgres" {
  name                         = "ca-postgres-${var.environment_name}-${random_string.resource_suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "postgres"
      image  = "docker.io/postgres:16-alpine"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "POSTGRES_USER"
        value = var.postgres_user
      }

      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-password"
      }

      env {
        name  = "POSTGRES_DB"
        value = var.postgres_db
      }

      env {
        name  = "PGDATA"
        value = "/var/lib/postgresql/data/pgdata"
      }

      volume_mounts {
        name = "postgres-data"
        path = "/var/lib/postgresql/data"
      }
    }

    volume {
      name         = "postgres-data"
      storage_type = "EmptyDir"
    }
  }

  secret {
    name  = "postgres-password"
    value = var.postgres_password
  }

  ingress {
    external_enabled = false
    target_port      = 5432
    transport        = "tcp"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    environment = var.environment_name
    application = "n8n"
    component   = "database"
  }
}

# User-assigned Managed Identity for n8n Container App
resource "azurerm_user_assigned_identity" "n8n" {
  name                = "id-n8n-${var.environment_name}-${random_string.resource_suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = var.environment_name
    application = "n8n"
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault for storing encryption key backup
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.environment_name}-${random_string.resource_suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Enable RBAC for access control
  enable_rbac_authorization = true

  tags = {
    environment = var.environment_name
    application = "n8n"
  }
}

# Grant Key Vault Secrets Officer role to the deployer
resource "azurerm_role_assignment" "keyvault_deployer" {
  count                = var.principal_id != "" ? 1 : 0
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.principal_id
}

# Grant Key Vault Secrets User role to n8n managed identity
resource "azurerm_role_assignment" "keyvault_n8n" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.n8n.principal_id
}

# n8n Container App
resource "azurerm_container_app" "n8n" {
  name                         = "ca-n8n-${var.environment_name}-${random_string.resource_suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.n8n.id]
  }

  template {
    min_replicas = 0
    max_replicas = 3

    container {
      name   = "n8n"
      image  = "docker.io/n8nio/n8n:${var.n8n_version}"
      cpu    = 1.0
      memory = "2Gi"

      # Database configuration
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }

      env {
        name  = "DB_POSTGRESDB_HOST"
        value = azurerm_container_app.postgres.ingress[0].fqdn
      }

      env {
        name  = "DB_POSTGRESDB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = var.postgres_db
      }

      env {
        name  = "DB_POSTGRESDB_USER"
        value = var.postgres_user
      }

      env {
        name        = "DB_POSTGRESDB_PASSWORD"
        secret_name = "postgres-password"
      }

      # n8n encryption key
      env {
        name        = "N8N_ENCRYPTION_KEY"
        secret_name = "n8n-encryption-key"
      }

      # Basic authentication
      env {
        name  = "N8N_BASIC_AUTH_ACTIVE"
        value = var.n8n_basic_auth_active ? "true" : "false"
      }

      env {
        name        = "N8N_BASIC_AUTH_USER"
        secret_name = "n8n-basic-auth-user"
      }

      env {
        name        = "N8N_BASIC_AUTH_PASSWORD"
        secret_name = "n8n-basic-auth-password"
      }

      # n8n configuration
      env {
        name  = "N8N_PORT"
        value = "5678"
      }

      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }

      env {
        name  = "GENERIC_TIMEZONE"
        value = "America/Los_Angeles"
      }

      env {
        name  = "TZ"
        value = "America/Los_Angeles"
      }
    }
  }

  secret {
    name  = "postgres-password"
    value = var.postgres_password
  }

  secret {
    name  = "n8n-encryption-key"
    value = random_string.n8n_encryption_key.result
  }

  secret {
    name  = "n8n-basic-auth-user"
    value = var.n8n_basic_auth_user
  }

  secret {
    name  = "n8n-basic-auth-password"
    value = var.n8n_basic_auth_password
  }

  ingress {
    external_enabled = true
    target_port      = 5678

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    environment = var.environment_name
    application = "n8n"
    component   = "app"
  }

  depends_on = [
    azurerm_container_app.postgres,
    azurerm_role_assignment.keyvault_n8n
  ]
}
