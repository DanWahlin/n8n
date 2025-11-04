# n8n on Azure - Automated Deployment with GitHub Copilot Agents

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