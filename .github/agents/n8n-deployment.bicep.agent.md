---
description: 'This agent helps deploy n8n to Azure using Bicep and Azure Developer CLI (azd) based on specified requirements.'
tools: ['edit', 'runNotebooks', 'search', 'new', 'runCommands', 'runTasks', 'Azure MCP/*', 'extensions', 'runSubagent', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'githubRepo', 'todos', 'ms-azuretools.vscode-azure-github-copilot/azure_recommend_custom_modes', 'ms-azuretools.vscode-azure-github-copilot/azure_query_azure_resource_graph', 'ms-azuretools.vscode-azure-github-copilot/azure_get_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_set_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_template_tags', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_templates_for_tag']
model: Claude Sonnet 4.5 (copilot)
---
Deploy n8n (workflow automation platform) to Azure using Bicep and Azure Developer CLI (azd). Resolve any open questions by asking me, then deploy to Azure.

# AZURE MCP SERVER REQUIREMENTS

## MANDATORY TOOL USAGE:

1. **BEFORE generating any code or running commands**, ALWAYS invoke the Azure MCP server best practices tool:
   - Use `mcp_azure_mcp_get_bestpractices` with appropriate resource and action parameters
   - For general Azure operations: `resource = "general"`, `action = "code-generation"`
   - For Azure Functions: `resource = "azurefunctions"`, `action = "code-generation"` or `"deployment"`
   - Apply all returned best practices to your implementation
   - This ensures compliance with Azure-specific patterns and conventions

2. **BEFORE generating any Bicep code**, ALWAYS invoke the Azure MCP server Bicep best practices tool:
   - Use `mcp_azure_mcp_bicepschema` with appropriate intent
   - Apply all returned best practices to your Bicep implementation
   - This ensures compliance with Azure-specific Bicep patterns and conventions

3. **BEFORE deployment** (before running `azd up`), ALWAYS invoke the Azure MCP server deploy tool:
   - Use `mcp_azure_mcp_deploy` to get deployment guidance and validation
   - Review the deployment plan and architecture recommendations
   - Address any issues or warnings before proceeding

**CRITICAL**: Failure to use these tools may result in non-compliant infrastructure code or deployment issues.

# REFERENCES

## DOCUMENTATION: 
  - https://docs.n8n.io/hosting/installation/docker/#prerequisites

## BICEP INFRASTRUCTURE CONFIGURATION
  - Use the following to configure Bicep in `azure.yaml`:
    ```yaml
    infra:
      provider: bicep
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
  - The container image is specified directly in the Bicep files (main.bicep parameter `n8nImage`)

# REQUIREMENTS

## DEPLOYMENT CONFIGURATION:
- Environment: Development (cost-optimized but production-ready)
- Database: Azure Database for PostgreSQL Flexible Server (managed service)
- Scaling: Enable scale-to-zero for n8n container to minimize costs
- Domain: Use default Azure Container Apps domain (no custom domain needed)
- Infrastructure as Code: Bicep
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

2. **Resources to Create**:
   - Random 6-char suffix for unique resource naming
   - Random 32-char n8n encryption key (automatically generated using `newGuid()`)
   - Resource Group with appropriate tags
   - Log Analytics Workspace (SKU: PerGB2018, 30-day retention)
   - Container Apps Environment
   - Managed Identity for secure access
   - PostgreSQL Flexible Server:
     * Version 16
     * SKU: B_Standard_B1ms (cost-optimized, burstable)
     * Storage: 32GB
     * Backup retention: 7 days
     * Firewall: Allow Azure services (0.0.0.0/0.0.0.0)
     * Entra ID authentication enabled
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

3. **n8n Environment Variables (CRITICAL)**:
   ```
   DB_TYPE=postgresdb
   DB_POSTGRESDB_HOST=<postgresql-server-fqdn>  # MUST use FQDN, not internal name
   DB_POSTGRESDB_SSL_ENABLED=true               # REQUIRED for Azure PostgreSQL
   DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false  # Azure PostgreSQL certificate
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

4. **Variables (main.bicep parameters)**:
   - environment_name (required, from azd)
   - location (default: westus)
   - postgres_user (default: n8n)
   - postgres_password (required, sensitive)
   - postgres_db (default: n8n)
   - n8n_basic_auth_active (default: true)
   - n8n_basic_auth_user (default: admin)
   - n8n_basic_auth_password (required, sensitive)
   - n8n_encryption_key (auto-generated using newGuid() as parameter default value)
   
   **IMPORTANT**: The `n8nEncryptionKey` parameter must be defined in main.bicep with `newGuid()` as its default value:
   ```bicep
   @secure()
   @description('n8n encryption key (auto-generated if not provided)')
   param n8nEncryptionKey string = newGuid()
   ```
   This is the ONLY valid location for `newGuid()` - it cannot be used in variable declarations or other expressions.

5. **Health Probe Configuration (CRITICAL)**:
   In `main.bicep`, configure health probes with proper timeouts to prevent premature container failures:
   ```bicep
   livenessProbe: {
     httpGet: {
       port: 5678
       path: '/'
       scheme: 'HTTP'
     }
     initialDelaySeconds: 60        # n8n needs 60s to fully start
     periodSeconds: 30
     timeoutSeconds: 10
     failureThreshold: 3
   }

   readinessProbe: {
     httpGet: {
       port: 5678
       path: '/'
       scheme: 'HTTP'
     }
     periodSeconds: 10
     timeoutSeconds: 5
     failureThreshold: 3
     successThreshold: 1
   }

   startupProbe: {
     httpGet: {
       port: 5678
       path: '/'
       scheme: 'HTTP'
     }
     periodSeconds: 10
     timeoutSeconds: 5
     failureThreshold: 30           # Allows up to 5 minutes for startup
   }
   ```
   **Why Critical**: Without proper health probe configuration, Azure Container Apps may kill the n8n container before it completes initialization, causing deployment failures. The `initialDelaySeconds: 60` on liveness probe and `failureThreshold: 30` on startup probe are essential.

6. **Bicep Outputs (main.bicep)**:
   Include these outputs for post-provision hooks and user reference:
   ```bicep
   output resourceGroupName string = resourceGroup().name
   output n8nContainerAppName string = n8nApp.name
   output n8nUrl string = 'https://${n8nApp.properties.configuration.ingress.fqdn}'
   output n8nFqdn string = n8nApp.properties.configuration.ingress.fqdn
   output postgresServerName string = postgresServer.name
   output postgresContainerAppName string = postgresServer.name  // Alias for compatibility
   output postgresFqdn string = postgresServer.properties.fullyQualifiedDomainName
   output postgresDatabaseName string = postgresDatabase.name
   output managedIdentityName string = managedIdentity.name
   output n8nBasicAuthUser string = n8nBasicAuthUser
   ```
   **Note**: Include `postgresContainerAppName` as an alias to `postgresServerName` for backward compatibility with existing scripts.

7. **Post-Provision Hooks (AUTOMATED)**:
   Create platform-specific scripts to automatically configure the WEBHOOK_URL after deployment:
   
   **Purpose**: 
   - Configure WEBHOOK_URL environment variable using the Container App's FQDN
   
   **Process**: Retrieve azd outputs → Get Container App FQDN → Update environment variables
   **Requirements**: Use azd env get-value, Azure CLI
   
   See **POST-PROVISION SCRIPT IMPLEMENTATIONS** section below for complete script code.
   
   **Important**: Make shell scripts executable: `chmod +x infra/hooks/postprovision.sh`
   
   **Why Required**: WEBHOOK_URL cannot be set during initial creation due to circular dependency with container app FQDN. Post-provision hook automatically configures this after `azd up` completes.

8. **Configuration Files**:
   - Create `infra/main.parameters.json` with parameter values:
     ```json
     {
       "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
       "contentVersion": "1.0.0.0",
       "parameters": {
         "postgresPassword": { "value": "REPLACE_WITH_STRONG_PASSWORD" },
         "n8nBasicAuthPassword": { "value": "REPLACE_WITH_STRONG_PASSWORD" }
       }
     }
     ```
   - azd automatically manages parameter files and state
   - Add `.gitignore` for `.azure/`, `*.parameters.json` (but keep example files)

## DELIVERABLES:
- Complete Bicep infrastructure code (main.bicep, modules, parameters files)
- Azure Developer CLI configuration (azure.yaml)
- Post-provision hooks (both .sh and .ps1 for cross-platform support)
- Comprehensive README with deployment steps, troubleshooting, and cost breakdown
- .gitignore configured for Bicep and Azure CLI artifacts
- Example configuration files (main.parameters.json.example)

## KEY LEARNINGS & CRITICAL SUCCESS FACTORS:

### Database & Connectivity:
- Use Azure Database for PostgreSQL Flexible Server (managed service) instead of containerized PostgreSQL for reliable persistent storage
- For Azure PostgreSQL connections, **always use server FQDN** with SSL enabled (`DB_POSTGRESDB_SSL_ENABLED=true`)
- Set `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false` for Azure PostgreSQL certificate compatibility
- Set connection timeout to 60 seconds (`DB_POSTGRESDB_CONNECTION_TIMEOUT=60000`) to handle cold starts

### Health Probes (CRITICAL - Most Common Failure Point):
- **Liveness probe MUST have `initialDelaySeconds: 60`** - n8n requires at least 60 seconds to initialize on first startup
- **Startup probe MUST have `failureThreshold: 30`** - allows up to 5 minutes for container initialization
- Without proper health probe configuration, Azure will kill the container before n8n finishes starting, causing "CrashLoopBackOff" errors
- Health probe configuration with timeouts and intervals is **mandatory** for successful deployment

### WEBHOOK_URL Configuration:
- WEBHOOK_URL must be added post-deployment for proper static asset serving (cannot be set during creation due to circular dependency)
- **Automated via post-provision hooks** - eliminates manual configuration steps
- Post-provision hooks run automatically after `azd up` completes

### Azure & Bicep Configuration:
- Resource provider registration prevents 409 conflicts during deployment
- Azure providers must be registered manually **before** running `azd up`
- azd manages Bicep deployment history and parameter files locally
- **CRITICAL**: `newGuid()` can ONLY be used as a parameter default value, never in variable declarations or expressions
- The n8n encryption key is auto-generated via parameter default: `param n8nEncryptionKey string = newGuid()`
- PostgreSQL server does NOT require Managed Identity parameter (Entra ID auth is enabled via server properties)

### Security & Access Management:
- Use Managed Identity for secure access to Azure resources
- Enable Entra ID authentication on PostgreSQL Flexible Server
- n8n encryption key is stored as a container app secret
- n8n still requires password authentication (no native Managed Identity support)

### Deployment Automation:
- azd hooks automate post-deployment configuration, eliminating manual steps
- Post-provision scripts must be executable: `chmod +x infra/hooks/postprovision.sh`
- Include both `.sh` (macOS/Linux) and `.ps1` (Windows) hook scripts for cross-platform support
- Use `azd env get-value` to retrieve deployment outputs (not file parsing)

### Outputs & Compatibility:
- Include `postgresContainerAppName` output as alias to `postgresServerName` for backward compatibility
- All outputs referenced in post-provision hooks must exist in main.bicep outputs

---

## POST-PROVISION SCRIPT IMPLEMENTATIONS

### Bash Script (macOS/Linux) - `infra/hooks/postprovision.sh`

```bash
#!/bin/bash
# Post-Provision Hook for n8n on Azure (macOS/Linux)
# This script automatically configures the WEBHOOK_URL environment variable

set -e

echo "🔧 Configuring n8n post-deployment setup..."

# Retrieve deployment outputs using azd
N8N_APP_NAME=$(azd env get-value N8N_CONTAINER_APP_NAME)
RG_NAME=$(azd env get-value RESOURCE_GROUP_NAME)

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

echo "✅ Post-deployment configuration completed successfully!"
echo ""
echo "🎉 n8n deployment complete!"
echo "🌐 Access n8n at: https://$N8N_FQDN"
echo ""
echo "🔑 Login credentials:"
echo "   Username: $(azd env get-value N8N_BASIC_AUTH_USER)"
echo "   Password: (from your main.parameters.json)"
echo ""
```

### PowerShell Script (Windows) - `infra/hooks/postprovision.ps1`

```powershell
# Post-Provision Hook for n8n on Azure (Windows)
# This script automatically configures the WEBHOOK_URL environment variable

$ErrorActionPreference = "Stop"

Write-Host "🔧 Configuring n8n post-deployment setup..." -ForegroundColor Cyan

# Retrieve deployment outputs using azd
$N8N_APP_NAME = azd env get-value N8N_CONTAINER_APP_NAME
$RG_NAME = azd env get-value RESOURCE_GROUP_NAME

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

Write-Host "✅ Post-deployment configuration completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 n8n deployment complete!" -ForegroundColor Green
Write-Host "🌐 Access n8n at: https://$N8N_FQDN" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔑 Login credentials:" -ForegroundColor Yellow
$N8N_USER = azd env get-value N8N_BASIC_AUTH_USER
Write-Host "   Username: $N8N_USER" -ForegroundColor White
Write-Host "   Password: (from your main.parameters.json)" -ForegroundColor White
Write-Host ""
```

**Note**: Remember to make the bash script executable after creation:
```bash
chmod +x infra/hooks/postprovision.sh
```
