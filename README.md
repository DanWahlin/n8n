# n8n on Azure Container Apps

Deploy [n8n](https://n8n.io) workflow automation platform to Azure using automated GitHub Copilot agents.

## GitHub Copilot Agents

This repository includes specialized GitHub Copilot agents in the `.github/agents/` directory that will guide you through deploying n8n to Azure. These agents handle all infrastructure setup, configuration, and deployment automatically.

### 1. Terraform Deployment Agent (`n8n.deployment.terraform.agent.md`)

An expert agent for deploying n8n to Azure using **Terraform** and Azure Developer CLI (azd).

**What This Agent Does:**
- Creates complete Terraform infrastructure code (main.tf, variables.tf, outputs.tf, providers.tf)
- Configures Azure Database for PostgreSQL Flexible Server for persistent storage
- Sets up Azure Container Apps with scale-to-zero capability
- Implements health probes and SSL database connections
- Handles resource provider registration to avoid deployment conflicts
- Manages environment variables and secrets securely
- Provides post-deployment webhook URL configuration
- Generates comprehensive documentation and troubleshooting guides

**Architecture Components:**
- Azure Container Apps (serverless hosting with 0-3 replica scaling)
- Azure Database for PostgreSQL Flexible Server (managed database)
- Azure Log Analytics (monitoring and logging)
- Container App secrets management

**Deployment Configuration:**
- Region: westus
- Environment: Development (cost-optimized)
- Database: PostgreSQL 16, B_Standard_B1ms SKU, 32GB storage
- Infrastructure: Terraform with local state management

---

### 2. Bicep Deployment Agent (`n8n-deployment.bicep.agent.md`)

An expert agent for deploying n8n to Azure using **Bicep** and Azure Developer CLI (azd).

**What This Agent Does:**
- Creates complete Bicep infrastructure templates (main.bicep, modules, parameters)
- Configures PostgreSQL Flexible Server with SSL/TLS encryption
- Implements Azure Key Vault for encryption key backup
- Sets up managed identity for secure resource access
- Configures Entra ID authentication for PostgreSQL
- Manages RBAC permissions and role assignments
- Generates cross-platform post-provision hooks (.sh and .ps1)
- Creates comprehensive deployment documentation

**Architecture Components:**
- Azure Container Apps (serverless hosting with scale-to-zero)
- Azure Database for PostgreSQL Flexible Server (managed database)
- Azure Key Vault (encryption key backup)
- Azure Log Analytics (monitoring)
- Managed Identity (secure access without credentials)

**Deployment Configuration:**
- Region: westus3
- Environment: Development (cost-optimized)
- Database: PostgreSQL Flexible Server with SSL
- Infrastructure: Bicep with azd-managed deployment

---

## How to Use These Agents

### Activating an Agent

**Option 1: Command Palette**
```
1. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Windows/Linux)
2. Type "Chat: Select Participants and Tools"
3. Choose the desired agent (Terraform or Bicep)
```

**Option 2: Chat Interface**
```
1. Open GitHub Copilot Chat
2. Type @ followed by the agent name
3. The agent will guide you through deployment
```

**Option 3: Direct Invocation**
```
1. Open Copilot Chat
2. Ask: "Deploy n8n to Azure using Terraform" or "Deploy n8n to Azure using Bicep"
3. The appropriate agent will activate and guide you
```

### What to Expect

When you activate an agent, it will:

1. **Ask clarifying questions** about your preferences (if needed)
2. **Generate all infrastructure code** (Terraform or Bicep files)
3. **Create configuration files** (azure.yaml, variable examples, .gitignore)
4. **Provide deployment instructions** (step-by-step commands)
5. **Generate documentation** (README with troubleshooting, cost estimates, management commands)
6. **Guide post-deployment steps** (webhook configuration, testing, verification)

### Prerequisites

Before activating an agent, ensure you have installed:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (v2.50.0+)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (v1.5.0+)
- [Terraform](https://terraform.io/downloads) (v1.5.0+) - for Terraform agent
- An active Azure subscription

### Quick Start Example

```bash
# 1. Activate the Terraform agent in Copilot Chat
"Deploy n8n to Azure using Terraform"

# 2. Follow the agent's guidance - it will generate all files

# 3. The agent will instruct you to run:
az login
azd init
azd up

# 4. Access your deployed n8n instance at the provided URL
```

---

## Agent Capabilities

Both agents provide:

✅ **Complete infrastructure generation** - No manual coding required  
✅ **Azure best practices** - Security, cost optimization, reliability  
✅ **Automated secret generation** - Encryption keys, passwords  
✅ **Health monitoring setup** - Probes, logging, metrics  
✅ **Troubleshooting guidance** - Common issues and solutions  
✅ **Cost estimates** - Monthly pricing for different usage patterns  
✅ **Security recommendations** - Production-ready enhancements  
✅ **Deployment automation** - Single-command deployment with azd  

### Key Differences

| Feature | Terraform Agent | Bicep Agent |
|---------|----------------|-------------|
| **IaC Language** | Terraform (HCL) | Bicep (Azure-native) |
| **State Management** | Local (via azd) | Azure-managed |
| **Secrets Storage** | Container App secrets | Key Vault + Container App |
| **Managed Identity** | Not configured | Configured for Key Vault |
| **Post-provision Hooks** | Not required | Included (.sh/.ps1) |
| **Region** | westus | westus3 |

Choose **Terraform** if you prefer HCL or multi-cloud capabilities.  
Choose **Bicep** if you prefer Azure-native tooling and Key Vault integration.

---

## What Gets Generated

When you use an agent, you'll get a complete project structure:

```
n8n/
├── .github/agents/          # Agent configuration files
├── infra/                   # Infrastructure code (generated)
│   ├── main.tf/.bicep      # Main infrastructure
│   ├── variables.tf         # Configuration variables
│   ├── outputs.tf           # Output values
│   ├── providers.tf         # Provider configuration
│   └── *.tfvars.json       # Variable values
├── azure.yaml              # Azure Developer CLI config
├── .gitignore             # Git ignore rules
└── README.md              # Complete documentation
```

---

## Support & Resources

- **n8n Documentation**: https://docs.n8n.io/
- **Azure Container Apps**: https://learn.microsoft.com/azure/container-apps/
- **Azure Developer CLI**: https://learn.microsoft.com/azure/developer/azure-developer-cli/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/
- **Azure Bicep**: https://learn.microsoft.com/azure/azure-resource-manager/bicep/

For issues with the agents or deployment, the agents themselves can help troubleshoot by analyzing errors and providing solutions.

## License

This deployment configuration is provided as-is. n8n itself is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).

Before you begin, ensure you have the following installed:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (v2.50.0 or later)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) (azd v1.5.0 or later)
- [Terraform](https://www.terraform.io/downloads) (v1.5.0 or later)

### Installation Commands

**macOS** (using Homebrew):
```bash
brew install azure-cli
brew install azd
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Windows** (using Winget):
```powershell
winget install Microsoft.AzureCLI
winget install Microsoft.Azd
winget install Hashicorp.Terraform
```

## Quick Start

### 1. Clone and Configure

```bash
# Navigate to the project directory
cd /Users/danwahlin/Desktop/test/n8n

# Copy the example configuration
cp infra/main.tfvars.json.example infra/main.tfvars.json

# Edit the configuration file and set strong passwords
# Replace REPLACE_WITH_STRONG_PASSWORD with actual secure passwords
```

### 2. Login to Azure

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 3. Deploy with azd

```bash
# Initialize the environment
azd init

# Provision and deploy (this will prompt for environment name and location)
azd up
```

The deployment will:
1. Create all Azure resources using Terraform
2. Deploy n8n container app
3. Deploy PostgreSQL container app
4. Backup the encryption key to Key Vault
5. Output the n8n URL

### 4. Access n8n

After deployment completes, you'll see output like:

```
n8n URL: https://ca-n8n-xxxxx.westus.azurecontainerapps.io
```

Login credentials:
- **Username**: admin (or the value you set in `n8n_basic_auth_user`)
- **Password**: The value you set in `infra/main.tfvars.json` for `n8n_basic_auth_password`

## Configuration

### Environment Variables

The `infra/main.tfvars.json` file contains all configuration options:

```json
{
  "postgres_password": "YOUR_SECURE_PASSWORD",
  "n8n_basic_auth_password": "YOUR_SECURE_PASSWORD"
}
```

### Optional Variables

You can add these to `main.tfvars.json` to customize the deployment:

```json
{
  "postgres_password": "YOUR_SECURE_PASSWORD",
  "n8n_basic_auth_password": "YOUR_SECURE_PASSWORD",
  "postgres_user": "n8n",
  "postgres_db": "n8n",
  "n8n_basic_auth_active": true,
  "n8n_basic_auth_user": "admin",
  "location": "westus"
}
```

> **Note**: The n8n Docker image version is set to `latest` in the Terraform configuration. To use a specific version, edit `infra/main.tf` and change the image value.
```

## Cost Optimization

This deployment is optimized for development and low-cost operation:

### Scale-to-Zero
The n8n container app scales to zero replicas when idle, minimizing costs:
- **Min replicas**: 0
- **Max replicas**: 3
- **Idle timeout**: Automatic (Azure default)

### Resource Sizing
- **n8n Container**: 1.0 vCPU, 2 GiB memory
- **PostgreSQL Flexible Server**: B_Standard_B1ms (1 vCore, burstable)
- **PostgreSQL Storage**: 32GB with 7-day backup retention
- **Log Analytics**: 30-day retention, pay-per-GB

### Estimated Monthly Cost

**Scenario 1: Low Usage (4 hours/day)**
- Container Apps: ~$15-20/month
- PostgreSQL Flexible Server (B1ms): ~$12-15/month
- Storage (32GB): ~$4/month
- Log Analytics: ~$5/month
- **Total**: ~$36-44/month

**Scenario 2: Medium Usage (12 hours/day)**
- Container Apps: ~$45-60/month
- PostgreSQL Flexible Server (B1ms): ~$12-15/month
- Storage (32GB): ~$4/month
- Log Analytics: ~$10/month
- **Total**: ~$71-89/month

**Scenario 3: Always Running (24/7)**
- Container Apps: ~$90-120/month
- PostgreSQL Flexible Server (B1ms): ~$12-15/month
- Storage (32GB): ~$4/month
- Log Analytics: ~$15/month
- **Total**: ~$121-154/month

> **Note**: PostgreSQL Flexible Server runs 24/7 (always-on managed service). Costs shown are estimates and may vary based on usage patterns, data transfer, backup storage, and Azure region.

## Management Commands

### View Deployment Status

```bash
# Show all resources in the environment
azd show

# Get Terraform outputs
cd infra && terraform output
```

### Access Logs

```bash
# View n8n application logs
az containerapp logs show \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --follow

# View logs in Azure Portal
azd show --output json | jq -r '.resources[] | select(.type == "Microsoft.App/containerApps") | .id'
```

### Scale Configuration

To adjust scaling limits, edit `infra/main.tf`:

```hcl
template {
  min_replicas = 0  # Change to 1 to prevent scale-to-zero
  max_replicas = 5  # Increase for higher load
  ...
}
```

Then run:
```bash
azd deploy
```

### Retrieve Encryption Key

The n8n encryption key is critical for data security. It's automatically generated during deployment:

```bash
# Retrieve the encryption key from Terraform output
cd infra
terraform output -raw n8n_encryption_key
```

**⚠️ Important**: Store this key securely! You'll need it to:
- Restore n8n data
- Migrate to a different environment
- Recover from disaster scenarios

> **Tip**: The encryption key is also stored as a secret in the Container App. You can view it in the Azure Portal under the Container App's "Secrets" section.

## Monitoring

### Azure Portal

1. Navigate to your Container App in the Azure Portal
2. View **Metrics** for CPU, memory, and request statistics
3. Check **Log Stream** for real-time application logs
4. Use **Revisions** to manage deployments

### Log Analytics Queries

Access Log Analytics workspace and run KQL queries:

```kql
// n8n application logs
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "ca-n8n-<suffix>"
| order by TimeGenerated desc

// PostgreSQL logs
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "ca-postgres-<suffix>"
| order by TimeGenerated desc

// Error logs only
ContainerAppConsoleLogs_CL
| where Log_s contains "error" or Log_s contains "ERROR"
| order by TimeGenerated desc
```

## Troubleshooting

### Common Issues

#### 1. Container App Not Starting

**Problem**: Container app shows "Provisioning" or "Failed" state

**Solutions**:
```bash
# Check container logs
az containerapp logs show \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --tail 100

# Check revision status
az containerapp revision list \
  --name <container-app-name> \
  --resource-group <resource-group-name>
```

#### 2. Database Connection Errors

**Problem**: n8n cannot connect to PostgreSQL

**Solutions**:
- Verify PostgreSQL Flexible Server is running (check Azure Portal)
- Check database credentials in Container App secrets
- Ensure firewall rules allow Azure services (0.0.0.0)
- Verify SSL is enabled (`DB_POSTGRESDB_SSL_ENABLED=true`)

```bash
# Check PostgreSQL Flexible Server status
az postgres flexible-server show \
  --resource-group <resource-group-name> \
  --name <postgres-server-name> \
  --query state -o tsv

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group <resource-group-name> \
  --name <postgres-server-name> -o table
```

#### 3. Scale-to-Zero Issues

**Problem**: Container takes long to start after being idle

**Solution**: This is expected behavior. First request after scale-to-zero may take 30-60 seconds. To prevent this:

```bash
# Edit infra/main.tf and set min_replicas = 1
# Then redeploy
azd deploy
```

#### 4. PostgreSQL Connection Timeout

**Problem**: n8n shows "Connection timeout" errors

**Solutions**:
- Verify the PostgreSQL Flexible Server is in "Ready" state
- Check that the Container App can reach the database (same region)
- Increase connection timeout if needed (currently set to 60 seconds)

```bash
# Check PostgreSQL server state
az postgres flexible-server show \
  --resource-group <resource-group-name> \
  --name <postgres-server-name> \
  --query state -o tsv

# Restart the Container App
az containerapp revision restart \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --revision <revision-name>
```

### Enable Debug Logging

Add these environment variables to `infra/main.tf` for verbose logging:

```hcl
env {
  name  = "N8N_LOG_LEVEL"
  value = "debug"
}

env {
  name  = "N8N_LOG_OUTPUT"
  value = "console"
}
```

## Backup and Restore

### Backup Strategy

1. **Encryption Key**: Retrieved via Terraform output (`terraform output -raw n8n_encryption_key`)
2. **Database**: Azure Database for PostgreSQL Flexible Server with automated backups
   - **Backup retention**: 7 days (configurable in `infra/main.tf`)
   - **Backup type**: Automated, managed by Azure
   - **Geo-redundancy**: Optional (can be enabled for disaster recovery)

### Automated Database Backups

PostgreSQL Flexible Server automatically backs up your database:

```bash
# List available backups
az postgres flexible-server backup list \
  --resource-group <resource-group-name> \
  --name <postgres-server-name> -o table

# Restore from automated backup to a new server
az postgres flexible-server restore \
  --resource-group <resource-group-name> \
  --name <new-server-name> \
  --source-server <postgres-server-name> \
  --restore-time "2025-11-03T10:00:00Z"
```

### Manual Database Backup

For manual exports, use `pg_dump` with the server FQDN:

```bash
# Get PostgreSQL server FQDN
POSTGRES_FQDN=$(cd infra && terraform output -raw postgres_fqdn)
POSTGRES_USER=$(cd infra && terraform output -raw postgres_container_app_name)

# Create backup using pg_dump (requires PostgreSQL client tools)
pg_dump -h $POSTGRES_FQDN -U n8n -d n8n -F c -f n8n_backup_$(date +%Y%m%d).dump

# For SQL format:
pg_dump -h $POSTGRES_FQDN -U n8n -d n8n -f n8n_backup_$(date +%Y%m%d).sql
```

> **Note**: You'll need to install PostgreSQL client tools locally and provide the database password when prompted.

## Updating n8n

To update to a new n8n version:

```bash
# Edit infra/main.tf and change the image version
# Find the line: image  = "docker.io/n8nio/n8n:latest"
# Change to: image  = "docker.io/n8nio/n8n:1.x.x"

# Redeploy
azd deploy
```

Alternatively, keep `latest` to always use the newest version (requires redeployment to update).

## Cleanup

To remove all Azure resources:

```bash
# Delete all resources
azd down

# Or manually delete with Terraform
cd infra
terraform destroy
```

## Security Considerations

1. **Secrets Management**: All sensitive values are stored as Container App secrets (encryption key, database password, auth credentials)
2. **SSL/TLS Encryption**: PostgreSQL connections use SSL (`DB_POSTGRESDB_SSL_ENABLED=true`)
3. **Network Security**: PostgreSQL Flexible Server allows Azure services only (0.0.0.0 firewall rule)
4. **Basic Authentication**: n8n protected with username/password authentication
5. **HTTPS**: Container Apps automatically provide HTTPS endpoints
6. **Encryption Key**: n8n encryption key automatically generated (32 characters, alphanumeric + special)

### Recommended Security Enhancements

For production deployments:

1. **Custom Domain**: Configure custom domain with your own SSL certificate
2. **Network Isolation**: Use VNET integration for Container Apps and PostgreSQL
3. **Private Endpoints**: Enable private endpoints for PostgreSQL (no public access)
4. **Advanced Auth**: Integrate with Azure AD/Entra ID instead of basic auth
5. **Secret Rotation**: Implement automatic secret rotation
6. **Firewall Rules**: Restrict Container App ingress to specific IP addresses
7. **Managed Identity**: Configure managed identity for PostgreSQL authentication (requires additional setup)
8. **Geo-Redundancy**: Enable geo-redundant backups for disaster recovery

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

For issues specific to:
- **n8n**: Visit [n8n Community](https://community.n8n.io/)
- **Azure**: Check [Azure Support](https://azure.microsoft.com/en-us/support/)
- **This deployment**: Open an issue in the repository

## License

This deployment configuration is provided as-is. n8n itself is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).
