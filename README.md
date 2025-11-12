# n8n on Azure Container Apps

Deploy n8n (workflow automation platform) to Azure using Bicep and Azure Developer CLI (azd).

## Architecture

This deployment creates a production-ready n8n instance on Azure with:

- **Azure Container Apps**: Serverless hosting for n8n with scale-to-zero capability
- **Azure Database for PostgreSQL Flexible Server**: Managed database for persistent storage
- **Azure Log Analytics**: Centralized monitoring and logging
- **Managed Identity**: Secure authentication to Azure resources

## Prerequisites

1. **Azure Subscription**: Active Azure subscription
2. **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Azure Developer CLI (azd)**: [Install azd](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
4. **Bash or PowerShell**: For running deployment scripts

## Quick Start

### 1. Register Azure Resource Providers

**IMPORTANT**: Run these commands before deployment to avoid 409 conflicts:

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.OperationalInsights
```

### 2. Configure Parameters

Copy the example parameters file and update with your secure passwords:

```bash
cp infra/main.parameters.json.example infra/main.parameters.json
```

Edit `infra/main.parameters.json` and replace the placeholder passwords with strong passwords:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "postgresPassword": {
      "value": "YOUR_SECURE_POSTGRES_PASSWORD"
    },
    "n8nBasicAuthPassword": {
      "value": "YOUR_SECURE_N8N_PASSWORD"
    }
  }
}
```

### 3. Deploy to Azure

```bash
# Initialize azd environment (first time only)
azd init

# When prompted, enter environment name: n8n
# Select region: westus (or your preferred region)

# Deploy infrastructure and configure n8n
azd up
```

The deployment will:
1. Create all Azure resources (Container Apps, PostgreSQL, Log Analytics)
2. Deploy the n8n container
3. Automatically configure WEBHOOK_URL via post-provision hooks

### 4. Access n8n

After deployment completes, you'll see output similar to:

```
🎉 n8n deployment complete!
🌐 Access n8n at: https://ca-n8n-xxxxxx.region.azurecontainerapps.io
🔑 Login credentials:
   Username: admin
   Password: (from your main.parameters.json)
```

Open the URL in your browser and log in with the credentials.

## Configuration

### Environment Variables

The deployment automatically configures these critical n8n environment variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `DB_TYPE` | `postgresdb` | Database type |
| `DB_POSTGRESDB_HOST` | Azure PostgreSQL FQDN | Database server address |
| `DB_POSTGRESDB_SSL_ENABLED` | `true` | Enable SSL for Azure PostgreSQL |
| `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED` | `false` | Azure PostgreSQL certificate compatibility |
| `DB_POSTGRESDB_CONNECTION_TIMEOUT` | `60000` | 60-second timeout for cold starts |
| `N8N_ENCRYPTION_KEY` | Auto-generated | Encryption key for credentials |
| `N8N_BASIC_AUTH_ACTIVE` | `true` | Enable basic authentication |
| `WEBHOOK_URL` | Auto-configured | Base URL for webhooks (set by post-provision hook) |

### Scaling

The Container App is configured with:
- **Min replicas**: 0 (scale-to-zero for cost savings)
- **Max replicas**: 3
- **CPU**: 1.0 core
- **Memory**: 2 GiB
- **Auto-scaling**: Based on HTTP requests (100 concurrent requests per replica)

### Health Probes

Critical health probe configuration ensures n8n starts successfully:

- **Startup Probe**: 5 minutes maximum startup time (30 failures × 10s)
- **Liveness Probe**: 60-second initial delay, checked every 30 seconds
- **Readiness Probe**: Checked every 10 seconds

## Cost Breakdown

**Estimated Monthly Cost** (Development environment):

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| Azure Container Apps | Consumption (1 vCPU, 2 GiB) | ~$30-60/month* |
| PostgreSQL Flexible Server | B_Standard_B1ms (32 GB) | ~$15-25/month |
| Log Analytics | PerGB2018 (30-day retention) | ~$5-10/month |
| **Total** | | **~$50-95/month** |

*Costs vary based on actual usage. Scale-to-zero reduces costs when idle.

**Cost Optimization Tips:**
- Container Apps scale to zero when idle (no compute charges)
- Use Azure Cost Management to track actual spending
- Consider reserved instances for production workloads

## Troubleshooting

### Container Fails to Start

**Symptom**: Container shows "CrashLoopBackOff" or repeatedly restarts

**Solution**: This is usually due to insufficient startup time. The deployment includes proper health probe configuration:
- Startup probe allows up to 5 minutes for initialization
- Liveness probe waits 60 seconds before first check

Check logs:
```bash
azd env get-value N8N_CONTAINER_APP_NAME
az containerapp logs show --name <container-app-name> --resource-group <resource-group> --follow
```

### Database Connection Issues

**Symptom**: n8n cannot connect to PostgreSQL

**Solution**: Verify:
1. Firewall rule allows Azure services (configured automatically)
2. SSL is enabled (`DB_POSTGRESDB_SSL_ENABLED=true`)
3. Connection timeout is sufficient (60 seconds)

Check PostgreSQL logs:
```bash
az postgres flexible-server show --name <server-name> --resource-group <resource-group>
```

### WEBHOOK_URL Not Set

**Symptom**: Webhooks not working, static assets not loading

**Solution**: The post-provision hook should set this automatically. If missing, manually update:

```bash
# Get values from azd
N8N_APP_NAME=$(azd env get-value N8N_CONTAINER_APP_NAME)
RG_NAME=$(azd env get-value RESOURCE_GROUP_NAME)
N8N_FQDN=$(az containerapp show --name "$N8N_APP_NAME" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv)

# Update environment variable
az containerapp update \
  --name "$N8N_APP_NAME" \
  --resource-group "$RG_NAME" \
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN"
```

### View Application Logs

```bash
# Get current environment name
azd env list

# View logs
azd env set <environment-name>
az containerapp logs show \
  --name $(azd env get-value N8N_CONTAINER_APP_NAME) \
  --resource-group $(azd env get-value RESOURCE_GROUP_NAME) \
  --follow
```

## Cleanup

To delete all Azure resources:

```bash
azd down --purge
```

This will remove:
- Resource group and all contained resources
- azd environment configuration
- Local state files

## Project Structure

```
.
├── azure.yaml                           # Azure Developer CLI configuration
├── infra/
│   ├── main.bicep                      # Main infrastructure template
│   ├── abbreviations.json              # Azure resource naming conventions
│   ├── main.parameters.json            # Deployment parameters (gitignored)
│   ├── main.parameters.json.example    # Example parameters file
│   ├── modules/
│   │   ├── container-apps-environment.bicep
│   │   ├── log-analytics.bicep
│   │   ├── managed-identity.bicep
│   │   ├── n8n-container-app.bicep
│   │   ├── postgres-database.bicep
│   │   └── postgres-server.bicep
│   └── hooks/
│       ├── postprovision.sh            # Post-deployment hook (macOS/Linux)
│       └── postprovision.ps1           # Post-deployment hook (Windows)
└── README.md
```

## Security Best Practices

1. **Strong Passwords**: Use complex passwords for PostgreSQL and n8n
2. **Managed Identity**: Container Apps use Managed Identity for Azure resource access
3. **SSL/TLS**: All connections use HTTPS and SSL (PostgreSQL)
4. **Secrets Management**: Sensitive values stored as Container App secrets
5. **Network Security**: PostgreSQL allows only Azure service connections

## Key Learnings & Success Factors

### Database & Connectivity
- Always use PostgreSQL server FQDN with SSL enabled
- Set connection timeout to 60 seconds for cold starts
- Azure PostgreSQL requires `SSL_REJECT_UNAUTHORIZED=false`

### Health Probes (Critical)
- Liveness probe MUST have 60-second initial delay
- Startup probe MUST allow 5+ minutes (30 failures × 10s)
- Proper health probe configuration prevents CrashLoopBackOff errors

### WEBHOOK_URL Configuration
- Auto-configured via post-provision hooks
- Required for proper static asset serving
- Cannot be set during initial creation (circular dependency)

### Deployment Automation
- Post-provision hooks eliminate manual configuration
- Resource providers must be registered before `azd up`
- Use `azd env get-value` to retrieve deployment outputs

## Support & Documentation

- **n8n Documentation**: https://docs.n8n.io/
- **Azure Container Apps**: https://learn.microsoft.com/en-us/azure/container-apps/
- **Azure Database for PostgreSQL**: https://learn.microsoft.com/en-us/azure/postgresql/
- **Azure Developer CLI**: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/

## License

MIT on Azure - Deployment Guide

Deploy [n8n](https://n8n.io) (workflow automation platform) to Azure using Bicep and Azure Developer CLI (azd).

## 🏗️ Architecture

This deployment creates a production-ready n8n instance on Azure with the following infrastructure:

- **Azure Container Apps**: Serverless hosting for n8n with scale-to-zero capability
- **Azure Database for PostgreSQL Flexible Server**: Managed database service for persistent storage
- **Azure Log Analytics**: Monitoring and diagnostics
- **User-Assigned Managed Identity**: Secure access to Azure resources
- **Azure Container Registry**: Container image management

## 📋 Prerequisites

Before deploying, ensure you have the following installed:

1. **Azure CLI** (`az`)
   ```bash
   # macOS
   brew install azure-cli
   
   # Verify installation
   az --version
   ```

2. **Azure Developer CLI** (`azd`)
   ```bash
   # macOS
   brew install azd
   
   # Verify installation
   azd version
   ```

3. **Azure Subscription**
   - An active Azure subscription with permissions to create resources
   - Login to Azure: `az login`

## 🚀 Deployment Steps

### Step 1: Register Azure Resource Providers

**CRITICAL**: Register these providers before deployment to avoid 409 conflicts:

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ContainerRegistry
```

Verify registration status:
```bash
az provider show --namespace Microsoft.App --query "registrationState"
```

### Step 2: Configure Deployment Parameters

Edit `infra/main.parameters.json` and replace the placeholder passwords:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "postgresPassword": {
      "value": "YOUR_STRONG_POSTGRES_PASSWORD_HERE"
    },
    "n8nBasicAuthPassword": {
      "value": "YOUR_STRONG_N8N_PASSWORD_HERE"
    }
  }
}
```

**Password Requirements**:
- At least 12 characters
- Mix of uppercase, lowercase, numbers, and symbols
- No dictionary words

### Step 3: Initialize Azure Developer CLI Environment

```bash
# Initialize azd with environment name 'n8n'
azd init -e n8n

# Set the Azure region (default: westus)
azd env set AZURE_LOCATION westus
```

### Step 4: Deploy to Azure

```bash
# Deploy infrastructure and application
azd up
```

This command will:
1. Create all Azure resources defined in Bicep
2. Deploy the n8n container to Azure Container Apps
3. Run post-provision hooks to configure WEBHOOK_URL
4. Backup the encryption key to Key Vault

**Deployment time**: Approximately 10-15 minutes

### Step 5: Access n8n

After deployment completes, you'll see output like:

```
🎉 n8n deployment complete!
🌐 Access n8n at: https://azca<unique-id>.westus.azurecontainerapps.io

🔑 Login credentials:
   Username: admin
   Password: (from your main.parameters.json)
```

Navigate to the URL and log in with the credentials from your parameters file.

## 🔧 Configuration

### Environment Variables

The following environment variables are automatically configured:

| Variable | Value | Description |
|----------|-------|-------------|
| `DB_TYPE` | `postgresdb` | Database type |
| `DB_POSTGRESDB_HOST` | `<server>.postgres.database.azure.com` | PostgreSQL FQDN |
| `DB_POSTGRESDB_SSL_ENABLED` | `true` | SSL connection required |
| `DB_POSTGRESDB_PORT` | `5432` | PostgreSQL port |
| `DB_POSTGRESDB_DATABASE` | `n8n` | Database name |
| `DB_POSTGRESDB_USER` | `n8n` | Database username |
| `N8N_ENCRYPTION_KEY` | Auto-generated | 32-character encryption key |
| `N8N_BASIC_AUTH_ACTIVE` | `true` | Enable basic auth |
| `N8N_BASIC_AUTH_USER` | `admin` | Login username |
| `N8N_PORT` | `5678` | n8n port |
| `N8N_PROTOCOL` | `https` | Protocol |
| `WEBHOOK_URL` | Auto-configured | Public webhook URL |

### Scaling Configuration

The deployment is configured with:
- **Min Replicas**: 0 (scale-to-zero when idle)
- **Max Replicas**: 3
- **Scale Rule**: HTTP requests (10 concurrent requests per replica)

To modify scaling:
```bash
az containerapp update \
  --name <app-name> \
  --resource-group <resource-group> \
  --min-replicas 1 \
  --max-replicas 5
```

## 📊 Cost Breakdown

**Estimated Monthly Cost** (Development/Scale-to-Zero Configuration):

| Resource | SKU/Tier | Estimated Cost |
|----------|----------|----------------|
| Container Apps Environment | Consumption | $0 (included) |
| n8n Container App | 1 vCPU, 2GB RAM, scale-to-zero | ~$10-30/month* |
| PostgreSQL Flexible Server | B1ms (Burstable) | ~$15/month |
| Log Analytics Workspace | PerGB2018 | ~$5/month |
| Container Registry | Basic | ~$5/month |
| **Total** | | **~$35-55/month** |

*Cost varies based on actual usage. Scale-to-zero reduces costs when n8n is idle.

**Production Configuration Costs**:
- Min replicas = 1: ~$60-80/month for Container Apps
- PostgreSQL General Purpose (GP_Standard_D2s_v3): ~$150/month

Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for precise estimates.

## 🔍 Troubleshooting

### Container App Not Starting

**Symptom**: Container app shows "CrashLoopBackOff" or constant restarts

**Solution**: Check health probe configuration and n8n startup time
```bash
# View container logs
az containerapp logs show \
  --name <app-name> \
  --resource-group <resource-group> \
  --tail 100

# Increase startup probe failure threshold if needed
# The deployment already sets failureThreshold: 30 (5 minutes)
```

### Database Connection Issues

**Symptom**: n8n cannot connect to PostgreSQL

**Solution**: Verify connection settings and firewall rules
```bash
# Test PostgreSQL connectivity
az postgres flexible-server connect \
  --name <server-name> \
  --admin-user n8n \
  --database-name n8n

# Verify firewall rules allow Azure services
az postgres flexible-server firewall-rule list \
  --resource-group <resource-group> \
  --name <server-name>
```

### WEBHOOK_URL Not Configured

**Symptom**: Webhooks don't work, static assets fail to load

**Solution**: Verify post-provision hook executed successfully
```bash
# Manually configure WEBHOOK_URL
N8N_FQDN=$(az containerapp show \
  --name <app-name> \
  --resource-group <resource-group> \
  --query "properties.configuration.ingress.fqdn" -o tsv)

az containerapp update \
  --name <app-name> \
  --resource-group <resource-group> \
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN"
```

### Resource Provider Not Registered

**Symptom**: Deployment fails with "The subscription is not registered to use namespace..."

**Solution**: Register the required provider
```bash
az provider register --namespace <namespace>
# Wait for registration to complete
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN"
```

## 🔐 Security Best Practices

1. **Encryption Key Storage**: The n8n encryption key is stored as a container app secret
2. **Password Rotation**: Regularly rotate PostgreSQL and n8n passwords
3. **Access Control**: Use Azure RBAC to limit access to resources
4. **Network Security**: Consider using Private Endpoints for production
5. **Monitoring**: Enable Azure Monitor alerts for security events

## 🧹 Cleanup

To delete all resources:

```bash
# Delete the entire environment
azd down

# Or manually delete the resource group
az group delete --name rg-n8n --yes --no-wait
```

**Warning**: This will permanently delete all data. Export workflows before cleanup.

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Database for PostgreSQL Documentation](https://learn.microsoft.com/azure/postgresql/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

## 🤝 Contributing

Issues and pull requests are welcome! Please follow the standard GitHub workflow.

## 📄 License

This deployment template is provided as-is under the MIT License.
