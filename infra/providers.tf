# Terraform providers configuration for n8n deployment on Azure
# Uses AzureRM provider v4.x with resource provider registration disabled
# to avoid 409 conflicts during deployment

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  # CRITICAL: Set to "none" to avoid 409 conflicts during deployment
  # Resource providers must be registered manually before running azd up
  resource_provider_registrations = "none"
  
  features {}
}
