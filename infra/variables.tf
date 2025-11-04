# Terraform Variables for n8n on Azure
# This file defines all configurable parameters for the deployment

# Core Azure Configuration
variable "environment_name" {
  description = "Name of the azd environment (e.g., 'n8n')"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westus"
}

# PostgreSQL Configuration
variable "postgres_user" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "n8n"
}

variable "postgres_password" {
  description = "PostgreSQL administrator password (must be strong)"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "n8n"
}

# n8n Authentication Configuration
variable "n8n_basic_auth_active" {
  description = "Enable basic authentication for n8n"
  type        = bool
  default     = true
}

variable "n8n_basic_auth_user" {
  description = "n8n basic authentication username"
  type        = string
  default     = "admin"
}

variable "n8n_basic_auth_password" {
  description = "n8n basic authentication password (must be strong)"
  type        = string
  sensitive   = true
}
