# Variables for n8n deployment on Azure
# Configuration parameters for Container Apps, PostgreSQL, and n8n settings

variable "environment_name" {
  description = "The name of the azd environment"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "westus"
}

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
