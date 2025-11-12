# n8n on Azure with Terraform

Deploy [n8n](https://n8n.io) (workflow automation platform) to Azure using Terraform and Azure Developer CLI (azd).

## Architecture

This deployment creates a production-ready n8n instance with:

- **Azure Container Apps** - Serverless n8n hosting with scale-to-zero (0-3 replicas)
- **Azure Database for PostgreSQL Flexible Server** - Managed database (B_Standard_B1ms, 32GB storage)
- **Azure Log Analytics** - Monitoring and logging (30-day retention)
- **HTTPS Ingress** - Secure external access with Azure-managed domain
- **Basic Authentication** - Built-in user authentication

## Prerequisites

1. **Azure CLI** - [Install](https://learn.microsoft.com/cli/azure/install-azure-cli)
2. **Azure Developer CLI (azd)** - [Install](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. **Terraform** - [Install](https://developer.hashicorp.com/terraform/install)
4. **Azure Subscription** - [Free account](https://azure.microsoft.com/free/)

## Quick Start

### 1. Register Azure Resource Providers

**CRITICAL**: Run these commands before deployment to avoid 409 conflicts:

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.OperationalInsights
```

Registration takes 2-5 minutes. Verify with:
```bash
az provider show --namespace Microsoft.App --query "registrationState"
```

### 2. Configure Secrets

Create configuration file from template:

```bash
cp infra/main.tfvars.json.example infra/main.tfvars.json
```

Edit `infra/main.tfvars.json` with strong passwords:

```json
{
  "postgres_password": "YourStrongPassword123!",
  "n8n_basic_auth_password": "YourN8nPassword456!"
}
```

**Security Notes**:
- Use passwords with 16+ characters, mixed case, numbers, and symbols
- Never commit `main.tfvars.json` to version control (already in `.gitignore`)
- n8n encryption key is auto-generated during deployment

### 3. Initialize Environment

```bash
azd env new n8n
```

This creates environment configuration in `.azure/n8n/`.

### 4. Deploy to Azure

```bash
azd up
```

This will:
1. Provision Azure resources (5-10 minutes)
2. Deploy n8n container
3. Configure WEBHOOK_URL automatically via post-provision hook

## Post-Deployment

### Access n8n

After deployment completes, the output shows:

```
🎉 n8n deployment complete!
🌐 Access n8n at: https://ca-n8n-n8n-xxxxxx.region.azurecontainerapps.io
```

Login credentials:
- **Username**: `admin` (default, configurable in `variables.tf`)
- **Password**: From your `main.tfvars.json`

### Retrieve Encryption Key

**IMPORTANT**: Save your encryption key securely before creating workflows:

```bash
cd .azure/n8n/infra
terraform output -raw n8n_encryption_key
```

Store this in a password manager - it's required for data encryption.

### View All Outputs

```bash
cd .azure/n8n/infra
terraform output
```

## Configuration

### Environment Variables

Customize in `infra/variables.tf`:

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `westus` | Azure region |
| `postgres_user` | `n8n` | Database admin username |
| `postgres_db` | `n8n` | Database name |
| `n8n_basic_auth_active` | `true` | Enable basic auth |
| `n8n_basic_auth_user` | `admin` | n8n username |

### Scaling Configuration

n8n Container App auto-scales (0-3 replicas):
- **Scale to Zero**: Enabled for cost savings
- **CPU**: 1.0 core per replica
- **Memory**: 2Gi per replica

Modify in `infra/main.tf`:

```hcl
template {
  min_replicas = 0  # Change to 1 to always keep running
  max_replicas = 3  # Increase for higher load
  
  container {
    cpu    = 1.0   # Adjust CPU allocation
    memory = "2Gi" # Adjust memory allocation
  }
}
```

## Cost Breakdown

**Estimated monthly cost: $25-40** (with scale-to-zero)

| Resource | SKU | Cost |
|----------|-----|------|
| PostgreSQL Flexible Server | B_Standard_B1ms | ~$15/month |
| Container Apps Environment | Consumption | ~$0/month (base) |
| n8n Container App | 1 vCPU, 2Gi | ~$10-25/month (varies with usage) |
| Log Analytics | PerGB2018 | ~$0-2/month (30-day retention) |

**Cost Optimization Tips**:
- Scale-to-zero minimizes container costs during inactivity
- Burstable PostgreSQL tier reduces database costs
- Monitor with Azure Cost Management

## Troubleshooting

### Container Not Starting

Check health probe configuration in `infra/main.tf`:
- Liveness probe has 60s `initial_delay` (n8n needs time to start)
- Startup probe allows 5 minutes with 30 failure threshold

View container logs:

```bash
az containerapp logs show \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --follow
```

### Database Connection Issues

Verify PostgreSQL connectivity:

1. Check firewall rule allows Azure services (0.0.0.0)
2. Confirm SSL is enabled (`DB_POSTGRESDB_SSL_ENABLED=true`)
3. Verify FQDN is used (not internal name)

### WEBHOOK_URL Not Set

Post-provision hook should set this automatically. If missing, manually update:

```bash
cd .azure/n8n/infra
N8N_APP_NAME=$(terraform output -raw n8n_container_app_name)
RG_NAME=$(terraform output -raw resource_group_name)
N8N_FQDN=$(az containerapp show --name "$N8N_APP_NAME" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv)

az containerapp update \
  --name "$N8N_APP_NAME" \
  --resource-group "$RG_NAME" \
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN"
```

### Provider Registration Errors (409)

If you see "ResourceProviderNotRegistered" errors:

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.OperationalInsights
```

Wait 2-5 minutes and retry deployment.

## Management Commands

### Update n8n Container

```bash
azd deploy
```

### View Infrastructure State

```bash
cd .azure/n8n/infra
terraform state list
terraform show
```

### Destroy Resources

```bash
azd down
```

**Warning**: This deletes all resources including the database. Backup data first.

## Security Best Practices

1. **Rotate Passwords**: Change `postgres_password` and `n8n_basic_auth_password` regularly
2. **Encryption Key**: Store `n8n_encryption_key` in Azure Key Vault or password manager
3. **Network Security**: Consider Azure Virtual Network integration for production
4. **Monitoring**: Enable Azure Monitor alerts for container restarts and errors
5. **Backup**: Configure PostgreSQL backup retention (default: 7 days)

## Additional Resources

- [n8n Documentation](https://docs.n8n.io)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Azure PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

## License

This deployment template is provided as-is. n8n is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md). on Azure - Automated Deployment with GitHub Copilot Agents

Deploy [n8n](https://n8n.io) workflow automation platform to Azure using specialized GitHub Copilot agents that handle everything for you.

## What Are These Agents?

This repository includes two expert GitHub Copilot agents located in `.github/agents/` that **completely automate** the deployment of n8n to Azure. No manual infrastructure coding required. Just activate an agent and follow along.

---

## 🚀 Available Agents

### 1. **Terraform Deployment Agent** (`n8n.deployment.terraform.agent.md`)

Deploys n8n using **Terraform** and Azure Developer CLI (azd).

**What It Builds:**
- Azure Container Apps (serverless n8n hosting, 0-3 replicas, scale-to-zero)
- Azure Database for PostgreSQL Flexible Server (managed database)
- Azure Log Analytics (monitoring)
- Complete Terraform infrastructure code
- Health probes with proper timeouts for n8n startup
- Automated post-provision hooks for WEBHOOK_URL configuration
- Secure secrets management

**Deployment Details:**
- **Region**: westus
- **Database**: PostgreSQL 16, B_Standard_B1ms SKU, 32GB storage
- **Infrastructure**: Terraform with local state (managed by azd)
- **Environment**: Development (cost-optimized)

---

### 2. **Bicep Deployment Agent** (`n8n-deployment.bicep.agent.md`)

Deploys n8n using **Bicep** and Azure Developer CLI (azd).

**What It Builds:**
- Azure Container Apps (serverless n8n hosting with scale-to-zero)
- Azure Database for PostgreSQL Flexible Server (SSL/TLS encryption)
- Azure Key Vault (encryption key backup)
- Azure Log Analytics (monitoring)
- Managed Identity (secure resource access)
- Complete Bicep infrastructure templates
- Cross-platform post-provision hooks (.sh and .ps1)
- RBAC permissions and role assignments

**Deployment Details:**
- **Region**: westus3
- **Database**: PostgreSQL Flexible Server with SSL
- **Infrastructure**: Bicep with azd-managed deployment
- **Environment**: Development (cost-optimized)

---

## 📋 Prerequisites

Before using an agent, install:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) v2.50.0+
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) v1.5.0+
- [Terraform](https://terraform.io/downloads) v1.5.0+ (for Terraform agent only)
- Active Azure subscription

**Quick Install (macOS with Homebrew):**
```bash
brew install azure-cli azd
brew tap hashicorp/tap && brew install hashicorp/tap/terraform  # Terraform agent only
```

**Quick Install (Windows with Winget):**
```powershell
winget install Microsoft.AzureCLI Microsoft.Azd
winget install Hashicorp.Terraform  # Terraform agent only
```

---

## 🎯 How to Use an Agent

Select one of the n8n agents from the GitHub Copilot chat window's drop-down (bottom of screen).

---

## ✨ What the Agent Does

Once activated, the agent will:

1. ✅ Generate all infrastructure code (Terraform/Bicep files)
2. ✅ Create configuration files (`azure.yaml`, `.gitignore`, example configs)
3. ✅ Generate secure secrets (encryption keys, passwords)
4. ✅ Provide step-by-step deployment commands
5. ✅ Configure health probes and monitoring
6. ✅ Set up automated post-provision hooks
7. ✅ Generate comprehensive documentation
8. ✅ Guide you through troubleshooting if needed

**You don't write any code—the agent does everything.**

---

## 📝 Quick Start Example

```bash
# 1. Open GitHub Copilot Chat and activate the Terraform agent
"Deploy n8n to Azure using Terraform"

# 2. The agent generates all files automatically

# 3. Follow the agent's instructions (typically):
az login
azd auth login
azd up

# 4. Access your n8n instance at the URL provided
```

---

## 🔑 Key Differences Between Agents

| Feature | Terraform Agent | Bicep Agent |
|---------|----------------|-------------|
| **IaC Language** | Terraform (HCL) | Bicep (Azure-native) |
| **State Management** | Local (via azd) | Azure-managed |
| **Secrets Storage** | Container App secrets | Key Vault + Container App |
| **Managed Identity** | Not configured | Configured for Key Vault |
| **Encryption Key Backup** | Manual retrieval | Automatic to Key Vault |
| **Region** | westus | westus3 |
| **Best For** | Multi-cloud, HCL familiarity | Azure-native, Key Vault integration |

**Choose Terraform** if you prefer HCL or plan multi-cloud deployments.  
**Choose Bicep** if you prefer Azure-native tooling and want Key Vault integration.

---

## 💰 Estimated Monthly Cost

**Development Environment (Low Usage - 4 hours/day):**
- Container Apps: ~$15-20
- PostgreSQL Flexible Server: ~$12-15
- Storage: ~$4
- Log Analytics: ~$5
- **Total**: ~$36-44/month

**Production Environment (24/7):**
- Container Apps: ~$90-120
- PostgreSQL Flexible Server: ~$12-15
- Storage: ~$4
- Log Analytics: ~$15
- **Total**: ~$121-154/month

> Scale-to-zero capability minimizes costs when n8n is idle.

---

## 🛡️ What the Agents Handle for You

✅ **Infrastructure as Code** - Complete Terraform or Bicep templates  
✅ **Resource Provisioning** - Container Apps, PostgreSQL, Log Analytics  
✅ **Security** - SSL/TLS encryption, secrets management, HTTPS endpoints  
✅ **Scaling** - Scale-to-zero configuration (0-3 replicas)  
✅ **Health Monitoring** - Liveness, readiness, and startup probes  
✅ **Automation** - Post-provision hooks for WEBHOOK_URL configuration  
✅ **Documentation** - Deployment guides, troubleshooting, cost estimates  
✅ **Error Handling** - Resource provider registration, timeout configurations  

---

## 🆘 Getting Help

If you encounter issues during deployment:

1. **Ask the agent** - It can analyze errors and provide solutions
2. **Check agent documentation** - Each agent includes troubleshooting guidance
3. **Review generated docs** - The agent creates comprehensive deployment guides

**For n8n-specific questions:**
- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)

**For Azure questions:**
- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

---

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Azure Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)