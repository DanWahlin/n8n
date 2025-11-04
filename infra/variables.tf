variable "environment_name" {
  description = "Name of the azd environment"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus"
}

variable "n8n_version" {
  description = "n8n Docker image version"
  type        = string
  default     = "latest"
}

variable "postgres_user" {
  description = "PostgreSQL database username"
  type        = string
  default     = "n8n"
}

variable "postgres_password" {
  description = "PostgreSQL database password"
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
  description = "n8n basic auth username"
  type        = string
  default     = "admin"
}

variable "n8n_basic_auth_password" {
  description = "n8n basic auth password"
  type        = string
  sensitive   = true
}
