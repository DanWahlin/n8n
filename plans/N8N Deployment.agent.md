---
description: 'This agent helps deploy n8n to Azure using Azure Developer CLI (azd) based on specified requirements.'
tools: ['edit', 'runNotebooks', 'search', 'new', 'runCommands', 'runTasks', 'Azure MCP/*', 'extensions', 'runSubagent', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'githubRepo', 'todos', 'ms-azuretools.vscode-azure-github-copilot/azure_recommend_custom_modes', 'ms-azuretools.vscode-azure-github-copilot/azure_query_azure_resource_graph', 'ms-azuretools.vscode-azure-github-copilot/azure_get_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_set_auth_context', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_template_tags', 'ms-azuretools.vscode-azure-github-copilot/azure_get_dotnet_templates_for_tag']
model: Claude Sonnet 4.5 (copilot)
---
I need to deploy n8n (workflow automation platform) to Azure using Bicep 
and Azure Developer CLI (azd). Resolve any open questions by asking me, then deploy to Azure.

# REFERENCES

## DOCUMENTATION: 
  - https://docs.n8n.io/hosting/installation/docker/#prerequisites

## BICEP INFRASTRUCTURE CONFIGURATION
  - Use the following to configure Bicep in `azure.yaml`:
    ```
    infra:
    provider: bicep
    path: infra
    ```
  - **IMPORTANT**: We are using the pre-built n8n Docker image from Docker Hub (`n8nio/n8n:latest`)
  - Do NOT include a `services:` section in `azure.yaml` - no local Docker build required
  - The container image is specified directly in the Bicep files (main.bicep parameter `n8nImage`)

# REQUIREMENTS

## DEPLOYMENT CONFIGURATION:
- Environment: Development (cost-optimized)
- Database: Use PostgreSQL Flexible Server
- Scaling: Enable scale-to-zero to minimize costs
- Domain: Use default Azure Container Apps domain (no custom domain needed)
- Infrastructure as Code: Bicep
- Use `westus3` for the Azure region
- Use `n8n-[generated short guid]` for the azd environment name

## ARCHITECTURE REQUIREMENTS:
- Azure Container Apps for serverless container hosting
- Azure Key Vault for encryption key storage
- Azure Log Analytics for monitoring
- Managed Identity for secure access (no connection strings)

## IMPORTANT IMPLEMENTATION DETAILS:
1. Generate the n8n encryption key in Bicep as a parameter with `newGuid()` as default value (not a variable - Bicep limitation)
2. Store encryption key as Container App secret (not Key Vault reference during creation)
3. Backup encryption key to Key Vault in post-provision hook
4. Use azd-managed Bicep deployment history (create main.parameters.json for parameters)
5. Post-provision hook should use `azd env get-value` to retrieve outputs (not file parsing)
6. Do NOT reference Container App FQDN in environment variables during creation (circular dependency)
7. **CRITICAL**: Key Vault purge protection MUST be enabled (`enablePurgeProtection: true`) - Azure requirement
8. **CRITICAL**: Enable SSL/TLS for PostgreSQL connections - set `DB_POSTGRESDB_SSL_ENABLED=true` and `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false`
9. **CRITICAL**: Enable Entra ID authentication on PostgreSQL and register Managed Identity as administrator
10. Post-provision hook needs to grant current user "Key Vault Secrets Officer" role before backup
11. Wait 10-15 seconds after role assignment for Azure RBAC propagation before writing secrets
12. n8n still requires password authentication (no native Managed Identity support), but SSL encrypts the connection


## DELIVERABLES:
- Complete Bicep infrastructure code (main.bicep, parameters files, modules, etc.)
- Azure Developer CLI configuration (azure.yaml)
- Post-provision hooks (both .sh and .ps1 for cross-platform support)
- Comprehensive README with deployment steps, troubleshooting, and cost breakdown
- .gitignore configured for Bicep and Azure CLI artifacts
- Example environment configuration files

## DEPLOYMENT:
- Deploy using the `azd up` command after setting up the project
- After deployment, if post-provision hook fails:
  1. Grant current user Key Vault Secrets Officer role
  2. Wait 10 seconds for RBAC propagation
  3. Run `.\infra\hooks\postprovision.ps1` manually
- If n8n shows database connection errors after deployment:
  1. Verify SSL settings are correctly configured in Container App environment variables
  2. Check PostgreSQL firewall rules allow Azure services (0.0.0.0)
  3. Restart Container App revision if needed
  4. Wait 30-60 seconds for container to start
- Test deployment by accessing the Container App FQDN URL
- Database connections are encrypted via SSL/TLS for production security
