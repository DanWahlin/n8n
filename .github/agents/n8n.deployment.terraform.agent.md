---
description: 'This agent helps deploy n8n to Azure using Terraform and Azure Developer CLI (azd) based on specified requirements.'
tools: ['edit', 'runNotebooks', 'search', 'new', 'runCommands', 'runTasks', 'Azure MCP/*', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'githubRepo', 'ms-azuretools.vscode-azure-github-copilot/azure_recommend_custom_modes', 'ms-azuretools.vscode-azure-github-copilot/azure_query_azure_resource_graph', 'ms-azuretools.vscode-azure-github-copilot/azure_get_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_set_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_template_tags', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_templates_for_tag', 'extensions', 'todos', 'runSubagent']
model: Claude Sonnet 4.5 (copilot)
---
Deploy n8n (workflow automation platform) to Azure using Terraform and Azure Developer CLI (azd). Resolve any open questions by asking me, then deploy to Azure.

# AZURE MCP SERVER REQUIREMENTS

## MANDATORY TOOL USAGE:

1. **BEFORE generating any code or running commands**, ALWAYS invoke the Azure MCP server best practices tool:
   - Use `mcp_azure_mcp_get_bestpractices` with appropriate resource and action parameters
   - For general Azure operations: `resource = "general"`, `action = "code-generation"`
   - For Azure Functions: `resource = "azurefunctions"`, `action = "code-generation"` or `"deployment"`
   - Apply all returned best practices to your implementation
   - This ensures compliance with Azure-specific patterns and conventions

2. **BEFORE generating any Terraform code**, ALWAYS invoke the Azure MCP server Terraform best practices tool:
   - Use `mcp_azure_mcp_azureterraformbestpractices` with appropriate intent
   - Apply all returned best practices to your Terraform implementation
   - This ensures compliance with Azure-specific Terraform patterns and conventions

3. **BEFORE deployment** (before running `azd up`), ALWAYS invoke the Azure MCP server deploy tool:
   - Use `mcp_azure_mcp_deploy` to get deployment guidance and validation
   - Review the deployment plan and architecture recommendations
   - Address any issues or warnings before proceeding

**CRITICAL**: Failure to use these tools may result in non-compliant infrastructure code or deployment issues.

# REFERENCES

## DOCUMENTATION: 
  - https://docs.n8n.io/hosting/installation/docker/#prerequisites

## TERRAFORM INFRASTRUCTURE CONFIGURATION
  - Use the following to configure Terraform in `azure.yaml`:
    ```yaml
    infra:
      provider: terraform
      path: infra
    
    hooks:
      postprovision:
        posix:
          shell: sh
          run: ./infra/hooks/postprovision.sh
        windows:
          shell: pwsh
          run: ./infra/hooks/postprovision.ps1
    ```
  - **IMPORTANT**: We are using the pre-built n8n Docker image from Docker Hub (`n8nio/n8n:latest`)
  - Do NOT include a `services:` section in `azure.yaml` - no local Docker build required
  - The container image is specified directly in the Terraform files (added in main.tf)

# REQUIREMENTS

## DEPLOYMENT CONFIGURATION:
- Environment: Development (cost-optimized but production-ready)
- Database: Azure Database for PostgreSQL Flexible Server (managed service)
- Scaling: Enable scale-to-zero for n8n container to minimize costs
- Domain: Use default Azure Container Apps domain (no custom domain needed)
- Infrastructure as Code: Terraform
- State Management: Local state (managed by azd)
- Use `westus` for the Azure region
- Use `n8n` for the azd environment name

## ARCHITECTURE REQUIREMENTS:
- Azure Container Apps for serverless n8n hosting
- Azure Log Analytics for monitoring
- Azure Database for PostgreSQL Flexible Server (managed database)

## CRITICAL IMPLEMENTATION STEPS:

1. **Pre-Deployment: Register Resource Providers**
   ```bash
   az provider register --namespace Microsoft.App
   az provider register --namespace Microsoft.DBforPostgreSQL
   az provider register --namespace Microsoft.OperationalInsights
   ```
   These commands must be run before `azd up` to avoid 409 conflicts.

2. **Terraform Providers (providers.tf)**:
   ```hcl
   terraform {
     required_version = ">= 1.5.0"
     required_providers {
       azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
       random  = { source = "hashicorp/random", version = "~> 3.6" }
     }
   }
   
   provider "azurerm" {
     resource_provider_registrations = "none"  # CRITICAL: Avoid 409 conflicts
     features {}
   }
   ```

3. **Resources to Create**:
   - Random 6-char suffix for unique resource naming
   - Random 32-char n8n encryption key (automatically generated)
   - Resource Group with appropriate tags
   - Log Analytics Workspace (SKU: PerGB2018, 30-day retention)
   - Container Apps Environment
   - PostgreSQL Flexible Server:
     * Version 16
     * SKU: B_Standard_B1ms (cost-optimized, burstable)
     * Storage: 32GB
     * Backup retention: 7 days
     * Firewall: Allow Azure services (0.0.0.0/0.0.0.0)
   - PostgreSQL Database (UTF8, en_US.utf8 collation)
   - n8n Container App:
     * Image: docker.io/n8nio/n8n:latest
     * CPU: 1.0, Memory: 2Gi
     * Replicas: 0-3 (scale-to-zero enabled)
     * Health probes with proper timeouts and intervals (CRITICAL for n8n startup):
       - Liveness: initial_delay=60s, interval=30s, timeout=10s, failures=3
       - Readiness: interval=10s, timeout=5s, failures=3, success=1
       - Startup: interval=10s, timeout=5s, failures=30 (allows 5min startup)
     * External ingress on port 5678

4. **n8n Environment Variables (CRITICAL)**:
   ```
   DB_TYPE=postgresdb
   DB_POSTGRESDB_HOST=<postgresql-server-fqdn>  # MUST use FQDN, not internal name
   DB_POSTGRESDB_SSL_ENABLED=true               # REQUIRED for Azure PostgreSQL
   DB_POSTGRESDB_PORT=5432
   DB_POSTGRESDB_CONNECTION_TIMEOUT=60000       # 60 seconds
   DB_POSTGRESDB_DATABASE=<var>
   DB_POSTGRESDB_USER=<var>
   DB_POSTGRESDB_PASSWORD=<secret>
   N8N_ENCRYPTION_KEY=<random-generated-secret>
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=<secret>
   N8N_BASIC_AUTH_PASSWORD=<secret>
   N8N_PORT=5678
   N8N_PROTOCOL=https
   ```

5. **Variables (variables.tf)**:
   - environment_name (required, from azd)
   - location (default: westus)
   - postgres_user (default: n8n)
   - postgres_password (required, sensitive)
   - postgres_db (default: n8n)
   - n8n_basic_auth_active (default: true)
   - n8n_basic_auth_user (default: admin)
   - n8n_basic_auth_password (required, sensitive)

6. **Health Probe Configuration (CRITICAL)**:
   In `infra/main.tf`, configure health probes with proper timeouts to prevent premature container failures:
   ```hcl
   liveness_probe {
     transport               = "HTTP"
     port                    = 5678
     path                    = "/"
     initial_delay           = 60        # n8n needs 60s to fully start
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
     failure_count_threshold = 30        # Allows up to 5 minutes for startup
   }
   ```
   **Why Critical**: Without proper health probe configuration, Azure Container Apps may kill the n8n container before it completes initialization, causing deployment failures. The `initial_delay=60` on liveness probe and `failure_count_threshold=30` on startup probe are essential.

7. **Terraform Outputs (outputs.tf)**:
   Include these outputs for post-provision hooks and user reference:
   ```hcl
   output "resource_group_name" { value = azurerm_resource_group.main.name }
   output "n8n_container_app_name" { value = azurerm_container_app.n8n.name }
   output "n8n_url" { value = "https://${azurerm_container_app.n8n.ingress[0].fqdn}" }
   output "n8n_fqdn" { value = azurerm_container_app.n8n.ingress[0].fqdn }
   output "postgres_server_name" { value = azurerm_postgresql_flexible_server.main.name }
   output "postgres_container_app_name" { value = azurerm_postgresql_flexible_server.main.name }  # Alias for compatibility
   output "postgres_fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn }
   output "postgres_database_name" { value = azurerm_postgresql_flexible_server_database.main.name }
   output "n8n_encryption_key" { value = random_password.n8n_encryption_key.result, sensitive = true }
   output "n8n_basic_auth_user" { value = var.n8n_basic_auth_user }
   ```
   **Note**: Include `postgres_container_app_name` as an alias to `postgres_server_name` for backward compatibility with existing scripts.

8. **Post-Provision Hooks (AUTOMATED)**:
   Create platform-specific scripts to automatically configure the WEBHOOK_URL after deployment:
   
   **Purpose**: Configure WEBHOOK_URL environment variable using the Container App's FQDN
   **Process**: Retrieve Terraform outputs → Get Container App FQDN → Update environment variables
   **Requirements**: Navigate to azd state directory, use Azure CLI to update container app
   
   See **POST-PROVISION SCRIPT IMPLEMENTATIONS** section below for complete script code.
   
   **Important**: Make shell scripts executable: `chmod +x infra/hooks/postprovision.sh`
   
   **Why Required**: WEBHOOK_URL cannot be set during initial creation due to circular dependency with container app FQDN. Post-provision hook automatically configures this after `azd up` completes.

9. **Configuration Files**:
   - Create `infra/main.tfvars.json.example` with password placeholders:
     ```json
     {
       "postgres_password": "REPLACE_WITH_STRONG_PASSWORD",
       "n8n_basic_auth_password": "REPLACE_WITH_STRONG_PASSWORD"
     }
     ```
   - azd automatically manages `main.tfvars.json` (not `terraform.tfvars.json`)
   - Copy example to actual: `cp infra/main.tfvars.json.example infra/main.tfvars.json`
   - Add `.gitignore` for `.azure/`, `*.tfstate`, `*.tfvars.json` (but not `*.tfvars.json.example`)

## DELIVERABLES:
- Complete Terraform infrastructure code (main.tf, variables.tf, outputs.tf, providers.tf)
- Azure Developer CLI configuration (azure.yaml)
- Comprehensive README with deployment steps, troubleshooting, and cost breakdown
- .gitignore configured for Terraform and Azure CLI artifacts
- Example environment configuration files (main.tfvars.json.example)

## KEY LEARNINGS & CRITICAL SUCCESS FACTORS:

### Database & Connectivity:
- Use Azure Database for PostgreSQL Flexible Server (managed service) instead of containerized PostgreSQL for reliable persistent storage
- For Azure PostgreSQL connections, **always use server FQDN** with SSL enabled (`DB_POSTGRESDB_SSL_ENABLED=true`)
- Set connection timeout to 60 seconds (`DB_POSTGRESDB_CONNECTION_TIMEOUT=60000`) to handle cold starts

### Health Probes (CRITICAL - Most Common Failure Point):
- **Liveness probe MUST have `initial_delay = 60`** - n8n requires at least 60 seconds to initialize on first startup
- **Startup probe MUST have `failure_count_threshold = 30`** - allows up to 5 minutes for container initialization
- Without proper health probe configuration, Azure will kill the container before n8n finishes starting, causing "CrashLoopBackOff" errors
- Health probe configuration with timeouts and intervals is **mandatory** for successful deployment

### WEBHOOK_URL Configuration:
- WEBHOOK_URL must be added post-deployment for proper static asset serving (cannot be set during creation due to circular dependency)
- **Automated via post-provision hooks** - eliminates manual configuration steps
- Post-provision hooks run automatically after `azd up` completes

### Terraform & Azure Configuration:
- Resource provider registration with `resource_provider_registrations = "none"` prevents 409 conflicts during deployment
- Azure providers must be registered manually **before** running `azd up`
- azd manages Terraform state locally - use `main.tfvars.json` (not `terraform.tfvars.json`)
- Use `random_password` (not `random_string`) for n8n encryption key generation

### Security & Access Management:
- n8n encryption key is stored as a container app secret
- n8n requires password authentication (no native Managed Identity support)

### Deployment Automation:
- azd hooks automate post-deployment configuration, eliminating manual steps
- Post-provision scripts must be executable: `chmod +x infra/hooks/postprovision.sh`
- Include both `.sh` (macOS/Linux) and `.ps1` (Windows) hook scripts for cross-platform support

### Outputs & Compatibility:
- Include `postgres_container_app_name` output as alias to `postgres_server_name` for backward compatibility
- All outputs referenced in post-provision hooks must exist in `outputs.tf`

---

## POST-PROVISION SCRIPT IMPLEMENTATIONS

### Bash Script (macOS/Linux) - `infra/hooks/postprovision.sh`

```bash
#!/bin/bash
# Post-Provision Hook for n8n on Azure (macOS/Linux)
# This script automatically configures the WEBHOOK_URL environment variable
# after the initial deployment completes

set -e

echo "🔧 Configuring n8n WEBHOOK_URL..."

# Navigate to azd's Terraform state directory
cd .azure/${AZURE_ENV_NAME}/infra

# Retrieve Container App name and Resource Group from Terraform outputs
N8N_APP_NAME=$(terraform output -raw n8n_container_app_name)
RG_NAME=$(terraform output -raw resource_group_name)

echo "📡 Retrieving n8n Container App URL..."
N8N_FQDN=$(az containerapp show \
  --name "$N8N_APP_NAME" \
  --resource-group "$RG_NAME" \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv)

if [ -z "$N8N_FQDN" ]; then
  echo "❌ Error: Could not retrieve Container App FQDN"
  exit 1
fi

echo "✅ n8n URL: https://$N8N_FQDN"

echo "🔄 Updating WEBHOOK_URL environment variable..."
az containerapp update \
  --name "$N8N_APP_NAME" \
  --resource-group "$RG_NAME" \
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN" \
  --output none

echo "✅ WEBHOOK_URL configured successfully!"
echo ""
echo "🎉 n8n deployment complete!"
echo "🌐 Access n8n at: https://$N8N_FQDN"
echo ""
echo "🔑 Login credentials:"
echo "   Username: $(terraform output -raw n8n_basic_auth_user)"
echo "   Password: (from your main.tfvars.json)"
echo ""
echo "⚠️  Important: Save your encryption key securely:"
echo "   Run: cd .azure/${AZURE_ENV_NAME}/infra && terraform output -raw n8n_encryption_key"
echo ""
```

### PowerShell Script (Windows) - `infra/hooks/postprovision.ps1`

```powershell
# Post-Provision Hook for n8n on Azure (Windows)
# This script automatically configures the WEBHOOK_URL environment variable
# after the initial deployment completes

$ErrorActionPreference = "Stop"

Write-Host "🔧 Configuring n8n WEBHOOK_URL..." -ForegroundColor Cyan

# Navigate to azd's Terraform state directory
Set-Location ".azure/$env:AZURE_ENV_NAME/infra"

# Retrieve Container App name and Resource Group from Terraform outputs
$N8N_APP_NAME = terraform output -raw n8n_container_app_name
$RG_NAME = terraform output -raw resource_group_name

# Get the Container App FQDN
Write-Host "📡 Retrieving n8n Container App URL..." -ForegroundColor Cyan
$N8N_FQDN = az containerapp show `
  --name $N8N_APP_NAME `
  --resource-group $RG_NAME `
  --query "properties.configuration.ingress.fqdn" `
  -o tsv

if ([string]::IsNullOrEmpty($N8N_FQDN)) {
  Write-Host "❌ Error: Could not retrieve Container App FQDN" -ForegroundColor Red
  exit 1
}

Write-Host "✅ n8n URL: https://$N8N_FQDN" -ForegroundColor Green

# Update the Container App with WEBHOOK_URL environment variable
Write-Host "🔄 Updating WEBHOOK_URL environment variable..." -ForegroundColor Cyan
az containerapp update `
  --name $N8N_APP_NAME `
  --resource-group $RG_NAME `
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN" `
  --output none

Write-Host "✅ WEBHOOK_URL configured successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 n8n deployment complete!" -ForegroundColor Green
Write-Host "🌐 Access n8n at: https://$N8N_FQDN" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔑 Login credentials:" -ForegroundColor Yellow
$N8N_USER = terraform output -raw n8n_basic_auth_user
Write-Host "   Username: $N8N_USER" -ForegroundColor White
Write-Host "   Password: (from your main.tfvars.json)" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Important: Save your encryption key securely:" -ForegroundColor Yellow
Write-Host "   Run: cd .azure/$env:AZURE_ENV_NAME/infra && terraform output -raw n8n_encryption_key" -ForegroundColor White
Write-Host ""
```

**Note**: Remember to make the bash script executable after creation:
```bash
chmod +x infra/hooks/postprovision.sh
```
