# n8n on Azure Container Apps

Deploy [n8n](https://n8n.io) workflow automation platform to Azure using Terraform and Azure Developer CLI (azd).

## Architecture

This solution deploys a cost-optimized n8n instance on Azure with the following components:

- **Azure Container Apps**: Serverless container hosting with scale-to-zero capability
- **PostgreSQL Container**: Internal PostgreSQL database (no external service needed)
- **Azure Key Vault**: Secure storage for encryption key backup
- **Azure Log Analytics**: Centralized logging and monitoring
- **Managed Identity**: Secure access to Azure resources without credentials

## Prerequisites

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
  "n8n_version": "latest",
  "postgres_user": "n8n",
  "postgres_db": "n8n",
  "n8n_basic_auth_active": true,
  "n8n_basic_auth_user": "admin",
  "location": "westus"
}
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
- **PostgreSQL Container**: 0.5 vCPU, 1 GiB memory
- **Log Analytics**: 30-day retention, pay-per-GB

### Estimated Monthly Cost

**Scenario 1: Low Usage (4 hours/day)**
- Container Apps: ~$15-20/month
- Log Analytics: ~$5/month
- Key Vault: ~$1/month
- **Total**: ~$21-26/month

**Scenario 2: Medium Usage (12 hours/day)**
- Container Apps: ~$45-60/month
- Log Analytics: ~$10/month
- Key Vault: ~$1/month
- **Total**: ~$56-71/month

**Scenario 3: Always Running (24/7)**
- Container Apps: ~$90-120/month
- Log Analytics: ~$15/month
- Key Vault: ~$1/month
- **Total**: ~$106-136/month

> **Note**: Actual costs may vary based on usage patterns, data transfer, and Azure region.

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

The n8n encryption key is critical for data security. It's backed up in Key Vault:

```bash
# Get Key Vault name
KEY_VAULT_NAME=$(cd infra && terraform output -raw key_vault_name)

# Retrieve the encryption key
az keyvault secret show \
  --vault-name $KEY_VAULT_NAME \
  --name n8n-encryption-key \
  --query value -o tsv
```

**⚠️ Important**: Store this key securely! You'll need it to:
- Restore n8n data
- Migrate to a different environment
- Recover from disaster scenarios

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
- Verify PostgreSQL container is running
- Check database credentials in Container App secrets
- Ensure PostgreSQL container has completed initialization

```bash
# Check PostgreSQL container logs
az containerapp logs show \
  --name ca-postgres-<suffix> \
  --resource-group <resource-group-name> \
  --tail 100
```

#### 3. Scale-to-Zero Issues

**Problem**: Container takes long to start after being idle

**Solution**: This is expected behavior. First request after scale-to-zero may take 30-60 seconds. To prevent this:

```bash
# Edit infra/main.tf and set min_replicas = 1
# Then redeploy
azd deploy
```

#### 4. Key Vault Access Denied

**Problem**: Post-provision hook fails to store encryption key

**Solutions**:
```bash
# Check your permissions on Key Vault
az role assignment list --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<kv-name>

# Grant yourself Key Vault Secrets Officer role
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee <your-user-principal-id> \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<kv-name>
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

1. **Encryption Key**: Automatically backed up to Key Vault during deployment
2. **Database**: PostgreSQL data is stored in EmptyDir volume (ephemeral)

⚠️ **Important**: The current setup uses EmptyDir storage, which means data is lost if the container restarts. For production, consider:

- Using Azure Database for PostgreSQL
- Implementing persistent volume claims
- Setting up automated backups

### Manual Database Backup

```bash
# Get PostgreSQL container FQDN
POSTGRES_FQDN=$(cd infra && terraform output -raw postgres_container_app_name)

# Create backup using pg_dump (requires exec into container or using Azure Container Apps exec)
az containerapp exec \
  --name ca-postgres-<suffix> \
  --resource-group <resource-group-name> \
  --command "/bin/sh" \
  --revision <revision-name>

# Inside the container:
pg_dump -U n8n n8n > /tmp/backup.sql
```

## Updating n8n

To update to a new n8n version:

```bash
# Edit infra/main.tfvars.json
{
  "n8n_version": "1.x.x",  # Specify version
  ...
}

# Redeploy
azd deploy
```

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

1. **Secrets Management**: All sensitive values are stored as Container App secrets
2. **Managed Identity**: n8n uses managed identity to access Key Vault (no credentials needed)
3. **Network Security**: PostgreSQL is internal-only (not exposed to internet)
4. **Encryption**: Encryption key is backed up to Key Vault
5. **HTTPS**: Container Apps automatically provide HTTPS endpoints

### Recommended Security Enhancements

For production deployments:

1. **Custom Domain**: Configure custom domain with your own SSL certificate
2. **Network Isolation**: Use VNET integration for Container Apps
3. **Advanced Auth**: Integrate with Azure AD/Entra ID
4. **Secret Rotation**: Implement automatic secret rotation
5. **Firewall Rules**: Restrict access to specific IP addresses

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
