# Terraform Providers Configuration for n8n on Azure
# This file configures the required providers and versions for deploying n8n to Azure

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
  features {}

  # CRITICAL: Prevents 409 conflicts during resource provider registration
  # Resource providers must be registered manually before running azd up
  # Run these commands first:
  #   az provider register --namespace Microsoft.App
  #   az provider register --namespace Microsoft.DBforPostgreSQL
  #   az provider register --namespace Microsoft.OperationalInsights
  resource_provider_registrations = "none"
}
