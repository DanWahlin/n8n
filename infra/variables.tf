variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "n8n"
}

variable "environment_name" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "n8n_image" {
  description = "n8n container image"
  type        = string
  default     = "docker.n8n.io/n8nio/n8n:latest"
}

variable "n8n_timezone" {
  description = "Timezone for n8n"
  type        = string
  default     = "America/New_York"
}

variable "container_cpu" {
  description = "CPU cores for container"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory in GB for container"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3
}

variable "storage_size_gb" {
  description = "Storage size in GB for SQLite volume"
  type        = number
  default     = 1
}
