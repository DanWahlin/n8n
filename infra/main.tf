# Main Terraform configuration for n8n deployment on Azure
# Creates Container Apps environment, PostgreSQL Flexible Server, and n8n container

# Generate random suffix for unique resource naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Generate random encryption key for n8n (32 characters)
resource "random_password" "n8n_encryption_key" {
  length  = 32
  special = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment_name}-${random_string.suffix.result}"
  location = var.location

  tags = {
    environment = var.environment_name
    application = "n8n"
    managed_by  = "terraform"
  }
}

# Log Analytics Workspace for Container Apps monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.environment_name}-${random_string.suffix.result}"
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
  name                       = "cae-${var.environment_name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    environment = var.environment_name
    application = "n8n"
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.environment_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  administrator_login    = var.postgres_user
  administrator_password = var.postgres_password

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  version    = "16"

  backup_retention_days = 7

  tags = {
    environment = var.environment_name
    application = "n8n"
  }
}

# PostgreSQL Firewall Rule - Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.postgres_db
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# n8n Container App
resource "azurerm_container_app" "n8n" {
  name                         = "ca-n8n-${var.environment_name}-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = 3

    container {
      name   = "n8n"
      image  = "docker.io/n8nio/n8n:latest"
      cpu    = 1.0
      memory = "2Gi"

      # Environment variables for n8n configuration
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }

      env {
        name  = "DB_POSTGRESDB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }

      env {
        name  = "DB_POSTGRESDB_SSL_ENABLED"
        value = "true"
      }

      env {
        name  = "DB_POSTGRESDB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_POSTGRESDB_CONNECTION_TIMEOUT"
        value = "60000"
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

      env {
        name        = "N8N_ENCRYPTION_KEY"
        secret_name = "n8n-encryption-key"
      }

      env {
        name  = "N8N_BASIC_AUTH_ACTIVE"
        value = tostring(var.n8n_basic_auth_active)
      }

      env {
        name  = "N8N_BASIC_AUTH_USER"
        value = var.n8n_basic_auth_user
      }

      env {
        name        = "N8N_BASIC_AUTH_PASSWORD"
        secret_name = "n8n-basic-auth-password"
      }

      env {
        name  = "N8N_PORT"
        value = "5678"
      }

      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }

      # CRITICAL: Health probes with proper timeouts for n8n startup
      # n8n requires at least 60 seconds to initialize
      liveness_probe {
        transport               = "HTTP"
        port                    = 5678
        path                    = "/"
        initial_delay           = 60
        interval_seconds        = 30
        timeout                 = 10
        failure_count_threshold = 3
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = 5678
        path                    = "/"
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 3
        success_count_threshold = 1
      }

      startup_probe {
        transport               = "HTTP"
        port                    = 5678
        path                    = "/"
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 30
      }
    }
  }

  # Secrets for sensitive configuration
  secret {
    name  = "postgres-password"
    value = var.postgres_password
  }

  secret {
    name  = "n8n-encryption-key"
    value = random_password.n8n_encryption_key.result
  }

  secret {
    name  = "n8n-basic-auth-password"
    value = var.n8n_basic_auth_password
  }

  # External ingress configuration
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
  }

  # Ensure database is created before deploying container
  depends_on = [
    azurerm_postgresql_flexible_server_database.main,
    azurerm_postgresql_flexible_server_firewall_rule.allow_azure
  ]
}
