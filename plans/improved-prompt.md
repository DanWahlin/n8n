# Improved Prompt for n8n Azure Deployment

## The Optimal Prompt

```
I need to deploy n8n (workflow automation platform) to Azure using Terraform 
and Azure Developer CLI (azd).

DOCUMENTATION: https://docs.n8n.io/hosting/installation/docker/#prerequisites

REQUIREMENTS

DEPLOYMENT CONFIGURATION:
- Environment: Development (cost-optimized)
- Database: Use PostgreSQL Flexible Server on Azure
- Scaling: Enable scale-to-zero to minimize costs
- Domain: Use default Azure Container Apps domain (no custom domain needed)
- Infrastructure as Code: Terraform
- State Management: Local state (managed by azd)
- Use westus for the region

ARCHITECTURE REQUIREMENTS:
- Azure Container Apps for serverless container hosting
- Azure Log Analytics for monitoring
- PostgreSQL container for database (development/cost-optimized)

IMPORTANT IMPLEMENTATION DETAILS:

1. **Terraform Providers (providers.tf)**:
   - azurerm version: "~> 4.0"
   - azuread version: "~> 2.53"
   - random version: "~> 3.6"
   - Required Terraform version: ">= 1.5.0"
   - CRITICAL: Set `resource_provider_registrations = "none"` in azurerm provider to avoid 409 conflicts
   - Include features block with key_vault.purge_soft_delete_on_destroy = true

2. **Random String Resources**:
   - Generate 6-character resource suffix (length=6, special=false, upper=false)
   - Generate 32-character n8n encryption key (length=32, special=true, upper=true, lower=true, numeric=true)

3. **Resource Naming Convention**:
   - Resource Group: "rg-${var.environment_name}-${random_string.resource_suffix.result}"
   - Log Analytics: "log-${var.environment_name}-${random_string.resource_suffix.result}"
   - Container Apps Environment: "cae-${var.environment_name}-${random_string.resource_suffix.result}"
   - PostgreSQL Container App: "ca-postgres-${var.environment_name}-${random_string.resource_suffix.result}"
   - n8n Container App: "ca-n8n-${var.environment_name}-${random_string.resource_suffix.result}"

4. **Tags for All Resources**:
   - environment = var.environment_name
   - application = "n8n"
   - azd-env-name = var.environment_name (for resource group)
   - component = "database" or "app" (for container apps)

5. **Log Analytics Workspace**:
   - SKU: "PerGB2018"
   - Retention: 30 days

6. **PostgreSQL Container App**:
   - Image: "docker.io/postgres:16-alpine"
   - CPU: 0.5, Memory: "1Gi"
   - Min/Max Replicas: 1/1 (always running)
   - Revision Mode: "Single"
   - Environment Variables: POSTGRES_USER, POSTGRES_PASSWORD (secret), POSTGRES_DB, PGDATA="/var/lib/postgresql/data/pgdata"
   - Volume: EmptyDir storage type mounted at /var/lib/postgresql/data
   - Ingress: external_enabled = false, target_port = 5432, transport = "tcp"
   - Secrets: postgres-password

7. **n8n Container App**:
   - Image: "docker.io/n8nio/n8n:latest"
   - CPU: 1.0, Memory: "2Gi"
   - Min/Max Replicas: 0/3 (scale-to-zero enabled)
   - Revision Mode: "Single"
   - Ingress: external_enabled = true, target_port = 5678
   - Depends on: azurerm_container_app.postgres
   - Secrets: postgres-password, n8n-encryption-key, n8n-basic-auth-user, n8n-basic-auth-password

8. **Health Probes (azurerm 4.0 syntax)**:
   - Liveness: transport="HTTP", port=5678, path="/", initial_delay=60, interval_seconds=30, timeout=10, failure_count_threshold=3
   - Readiness: transport="HTTP", port=5678, path="/", interval_seconds=10, timeout=5, failure_count_threshold=3, success_count_threshold=1
   - Startup: transport="HTTP", port=5678, path="/", interval_seconds=10, timeout=5, failure_count_threshold=30

9. **n8n Environment Variables (CRITICAL DATABASE CONFIG)**:
   - DB_TYPE = "postgresdb"
   - DB_POSTGRESDB_HOST = azurerm_container_app.postgres.name (just the name, NOT FQDN!)
   - DB_POSTGRESDB_PORT = "5432"
   - DB_POSTGRESDB_CONNECTION_TIMEOUT = "60000" (60 seconds)
   - DB_POSTGRESDB_DATABASE = var.postgres_db
   - DB_POSTGRESDB_USER = var.postgres_user
   - DB_POSTGRESDB_PASSWORD = secret reference
   - N8N_ENCRYPTION_KEY = secret reference (from random_string)
   - N8N_BASIC_AUTH_ACTIVE = var.n8n_basic_auth_active ? "true" : "false"
   - N8N_BASIC_AUTH_USER = secret reference
   - N8N_BASIC_AUTH_PASSWORD = secret reference
   - N8N_PORT = "5678"
   - N8N_PROTOCOL = "https"
   - N8N_LOG_LEVEL = "debug"
   - EXECUTIONS_MODE = "regular"
   - GENERIC_TIMEZONE = "America/Los_Angeles"
   - TZ = "America/Los_Angeles"

10. **Variables (variables.tf)**:
    - environment_name (required, from azd)
    - location (default: "westus")
    - n8n_version (default: "latest")
    - postgres_user (default: "n8n")
    - postgres_password (required, sensitive)
    - postgres_db (default: "n8n")
    - n8n_basic_auth_active (default: true)
    - n8n_basic_auth_user (default: "admin")
    - n8n_basic_auth_password (required, sensitive)

11. **Outputs (outputs.tf)**:
    - resource_group_name
    - location
    - n8n_url (https://${fqdn})
    - n8n_fqdn
    - container_app_name
    - postgres_container_app_name
    - log_analytics_workspace_name
    - container_app_environment_name
    - n8n_encryption_key (sensitive)

12. **Azure Developer CLI (azure.yaml)**:
```yaml
name: n8n-azure
metadata:
  template: n8n-azure@0.0.1

infra:
  provider: terraform
  path: infra
```

13. **Configuration Files**:
    - Create main.tfvars.json.example with postgres_password and n8n_basic_auth_password placeholders
    - azd will manage main.tfvars.json (not terraform.tfvars.json)

DELIVERABLES:
- Complete Terraform infrastructure code (main.tf, variables.tf, outputs.tf, etc.)
- Azure Developer CLI configuration (azure.yaml)
- Comprehensive README with deployment steps, troubleshooting, and cost breakdown
- .gitignore configured for Terraform and Azure CLI artifacts
- Example environment configuration files

Please implement the complete solution and deploy it using 'azd up'.
```

