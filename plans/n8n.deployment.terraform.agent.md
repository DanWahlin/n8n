---
description: 'This agent helps deploy n8n to Azure using Terraform and Azure Developer CLI (azd) based on specified requirements.'
tools: ['edit', 'runNotebooks', 'search', 'new', 'runCommands', 'runTasks', 'Azure MCP/*', 'extensions', 'runSubagent', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'githubRepo', 'todos', 'ms-azuretools.vscode-azure-github-copilot/azure_recommend_custom_modes', 'ms-azuretools.vscode-azure-github-copilot/azure_query_azure_resource_graph', 'ms-azuretools.vscode-azure-github-copilot/azure_get_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_set_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_template_tags', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_templates_for_tag']
model: Claude Sonnet 4.5 (copilot)
---
Deploy n8n (workflow automation platform) to Azure using Terraform and Azure Developer CLI (azd). Resolve any open questions by asking me, then deploy to Azure.

# REFERENCES

## DOCUMENTATION: 
  - https://docs.n8n.io/hosting/installation/docker/#prerequisites

## TERRAFORM INFRASTRUCTURE CONFIGURATION
  - Use the following to configure Terraform in `azure.yaml`:
    ```yaml
    infra:
      provider: terraform
      path: infra
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
     * Health probes: liveness, readiness, startup on port 5678, path "/"
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

6. **Post-Deployment: Add WEBHOOK_URL**
   ```bash
   N8N_FQDN=$(az containerapp show --name <container-app-name> --resource-group <rg-name> --query "properties.configuration.ingress.fqdn" -o tsv)
   az containerapp update --name <container-app-name> --resource-group <rg-name> --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN"
   ```
   **Why:** Required for n8n to serve static assets correctly. Cannot be set during initial creation due to circular dependency with the container app's FQDN.

7. **Configuration Files**:
   - Create main.tfvars.json.example with password placeholders
   - azd automatically manages main.tfvars.json (not terraform.tfvars.json)
   - Add .gitignore for .azure/, *.tfstate, *.tfvars.json

## DELIVERABLES:
- Complete Terraform infrastructure code (main.tf, variables.tf, outputs.tf, providers.tf)
- Azure Developer CLI configuration (azure.yaml)
- Comprehensive README with deployment steps, troubleshooting, and cost breakdown
- .gitignore configured for Terraform and Azure CLI artifacts
- Example environment configuration files (main.tfvars.json.example)

## DEPLOYMENT:
1. Register Azure resource providers (see step 1 above)
2. Run `azd up` to deploy all infrastructure
3. Wait for deployment to complete
4. Run post-deployment WEBHOOK_URL command (see step 6 above)
5. Access n8n at the provided Container App URL
6. Login with the configured basic auth credentials

## KEY LEARNINGS:
- Use Azure Database for PostgreSQL Flexible Server (managed service) instead of containerized PostgreSQL for reliable persistent storage
- For Azure PostgreSQL connections, always use server FQDN with SSL enabled (`DB_POSTGRESDB_SSL_ENABLED=true`)
- Health probes are critical to prevent premature container failures during n8n startup (liveness, readiness, startup probes)
- WEBHOOK_URL must be added post-deployment for proper static asset serving (cannot be set during creation due to circular dependency)
- Resource provider registration with `resource_provider_registrations = "none"` prevents 409 conflicts during deployment
- azd manages Terraform state locally - use main.tfvars.json (not terraform.tfvars.json)
