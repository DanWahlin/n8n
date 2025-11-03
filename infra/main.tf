terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Generate unique suffix for resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Generate encryption key for n8n
resource "random_string" "encryption_key" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment_name}-${var.location}"
  location = var.location

  tags = {
    Environment = var.environment_name
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = timestamp()
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# User Assigned Managed Identity for Container App
resource "azurerm_user_assigned_identity" "container_app" {
  name                = "id-${var.project_name}-${var.environment_name}-${var.location}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    Environment = var.environment_name
    Project     = var.project_name
  }
}
