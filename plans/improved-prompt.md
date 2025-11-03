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
- Azure Key Vault for encryption key storage
- Azure Log Analytics for monitoring
- Managed Identity for secure access (no connection strings)

IMPORTANT IMPLEMENTATION DETAILS:
1. Generate the n8n encryption key in Terraform using random_string resource
2. Store encryption key as Container App secret (not Key Vault reference during creation)
3. Backup encryption key to Key Vault in post-provision hook
4. Use azd-managed local Terraform state (create main.tfvars.json, not terraform.tfvars.json)
5. Post-provision hook should use absolute paths from .azure/<env-name>/infra directory
6. Do NOT reference Container App FQDN in environment variables during creation (circular dependency)
7. Avoid adding azd hooks unless they are absolutely needed!
8. Use the following to configure Terraform in `azure.yaml`:

# Terraform infrastructure configuration
infra:
  provider: terraform
  path: infra

DELIVERABLES:
- Complete Terraform infrastructure code (main.tf, variables.tf, outputs.tf, etc.)
- Azure Developer CLI configuration (azure.yaml)
- Post-provision hooks (both .sh and .ps1 for cross-platform support)
- Comprehensive README with deployment steps, troubleshooting, and cost breakdown
- .gitignore configured for Terraform and Azure CLI artifacts
- Example environment configuration files

Please implement the complete solution and deploy it using 'azd up'.
```

