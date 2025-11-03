# n8n on Azure

Deploy n8n workflow automation platform to Azure Container Apps with SQLite database for a cost-effective development environment (~$3-5/month).

## Architecture

This deployment uses:
- **Azure Container Apps** - Serverless container hosting with scale-to-zero
- **Azure Storage Account** - File share for SQLite database persistence
- **Azure Key Vault** - Secure storage for encryption keys
- **Azure Log Analytics** - Container logging and monitoring

## Prerequisites

Before you begin, ensure you have:

- **Azure Subscription** - [Get a free account](https://azure.microsoft.com/free/)
- **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **Azure Developer CLI (azd)** - [Install azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- **Terraform** - Version 1.5 or higher ([Install Terraform](https://developer.hashicorp.com/terraform/downloads))

### Install Terraform (if needed)

**macOS:**
```bash
brew install terraform
```

**Windows:**
```powershell
winget install Hashicorp.Terraform
```

**Linux:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## Quick Start

### 1. Login to Azure

```bash
az login
```

### 2. Deploy n8n

```bash
# Clone or navigate to this directory
cd n8n

# Initialize and deploy
azd up
```

The `azd up` command will:
1. Initialize Terraform
2. Provision Azure resources (Container Apps, Key Vault, Storage, etc.)
3. Generate and store the N8N_ENCRYPTION_KEY
4. Deploy the n8n container
5. Display the n8n URL

### 3. Access n8n

After deployment completes (2-3 minutes), visit the URL shown in the output:

```
https://<your-container-app>.azurecontainerapps.io
```

## Configuration

### Environment Variables

The deployment is configured via `infra/terraform.tfvars.json`:

```json
{
  "location": "eastus",
  "environment_name": "dev",
  "n8n_image": "docker.n8n.io/n8nio/n8n:latest",
  "n8n_timezone": "America/New_York",
  "storage_size_gb": 1
}
```

### Customization Options

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region | `eastus` |
| `environment_name` | Environment name | `dev` |
| `n8n_image` | n8n container image | `docker.n8n.io/n8nio/n8n:latest` |
| `n8n_timezone` | Timezone for n8n | `America/New_York` |
| `storage_size_gb` | Storage quota (GB) | `1` |
| `min_replicas` | Min container instances | `0` (scale-to-zero) |
| `max_replicas` | Max container instances | `3` |
| `container_cpu` | CPU cores | `0.5` |
| `container_memory` | Memory allocation | `1Gi` |

### Database Configuration

This deployment uses **SQLite** (default for n8n) with data persisted to an Azure File Share mounted at `/home/node/.n8n`.

**SQLite Characteristics:**
- ✅ Zero configuration required
- ✅ No separate database service costs
- ✅ Perfect for development and testing
- ✅ Supports up to ~100 workflows and moderate execution volume
- ⚠️ Not recommended for production with high concurrency
- ⚠️ Data stored in container volume (backed by Azure Files)

## Cost Breakdown

**Monthly Cost Estimate (Development):**

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| Container Apps | 0.5 vCPU, 1GB RAM, scale-to-zero | $2-3/month |
| Storage Account | LRS, 1GB file share | $0.20/month |
| Key Vault | Standard tier, minimal operations | $0.50/month |
| Log Analytics | 500MB free tier | $0-1/month |
| **Total** | | **~$3-5/month** |

**Cost Optimization Tips:**
- Scale-to-zero enabled (min replicas = 0) - saves cost when idle
- Container scales down after 10 minutes of inactivity
- Use Burstable/consumption tiers for all services
- Monitor usage with Azure Cost Management

## Local Testing

Test n8n locally before deploying:

```bash
# Run n8n with Docker
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n

# Access at http://localhost:5678
```

To stop:
```bash
docker stop n8n && docker rm n8n
```

## Management Commands

### View Logs

```bash
# Using azd
azd monitor --logs

# Using Azure CLI
az containerapp logs show \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --follow
```

### Update Configuration

1. Modify `infra/terraform.tfvars.json`
2. Run `azd up` to apply changes

### Restart Container

```bash
az containerapp revision restart \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --revision <revision-name>
```

### Delete Deployment

```bash
azd down
```

This removes all Azure resources created by the deployment.

## Monitoring

### Health Check

n8n provides a health endpoint at `/healthz` which is used for liveness and readiness probes.

### View Metrics (Optional)

To enable Prometheus metrics:

1. Add to Container App environment variables in `infra/container-app.tf`:
   ```hcl
   env {
     name  = "N8N_METRICS"
     value = "true"
   }
   ```

2. Access metrics at: `https://<your-url>/metrics`

### Azure Portal

View logs, metrics, and container status:
```
https://portal.azure.com → Resource Groups → rg-n8n-dev-<location>
```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
az containerapp logs show --name <name> --resource-group <rg> --follow
```

**Common issues:**
- Encryption key not set → Re-run `./hooks/postprovision.sh`
- Image pull errors → Verify `n8n_image` in `terraform.tfvars.json`
- Storage mount issues → Check Azure Files quota and connectivity

### Can't Access n8n URL

**Verify ingress:**
```bash
cd infra
terraform output n8n_url
```

**Check container status:**
```bash
az containerapp show --name <name> --resource-group <rg> --query "properties.runningStatus"
```

### Data Persistence Issues

Data is stored in Azure Files at `/home/node/.n8n`.

**Verify volume mount:**
```bash
az containerapp show --name <name> --resource-group <rg> \
  --query "properties.template.volumes"
```

### Encryption Key Errors

If n8n reports encryption key issues:

1. Verify Key Vault secret exists:
   ```bash
   az keyvault secret show --vault-name <kv-name> --name n8n-encryption-key
   ```

2. Check managed identity permissions:
   ```bash
   az role assignment list --assignee <identity-principal-id> --scope <keyvault-id>
   ```

## Migration to Production

When ready for production, migrate to PostgreSQL:

### 1. Add PostgreSQL Flexible Server

Create `infra/database.tf`:
```hcl
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-n8n-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  version    = "15"
  
  administrator_login    = "n8nadmin"
  administrator_password = azurerm_key_vault_secret.db_password.value
  
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
}
```

### 2. Update Container App Environment

Change database variables in `infra/container-app.tf`:
```hcl
env {
  name  = "DB_TYPE"
  value = "postgresdb"
}
env {
  name  = "DB_POSTGRESDB_HOST"
  value = azurerm_postgresql_flexible_server.main.fqdn
}
# Add DB_POSTGRESDB_DATABASE, DB_POSTGRESDB_USER, DB_POSTGRESDB_PASSWORD
```

### 3. Export and Import Data

```bash
# Export from SQLite (in running container)
docker exec n8n n8n export:workflow --all --output=/backup/workflows.json
docker exec n8n n8n export:credentials --all --output=/backup/credentials.json

# Import to PostgreSQL
docker exec n8n n8n import:workflow --input=/backup/workflows.json
docker exec n8n n8n import:credentials --input=/backup/credentials.json
```

**Cost Impact:** +$12-15/month for PostgreSQL Burstable tier

## Security Considerations

- ✅ Encryption key stored in Azure Key Vault
- ✅ Managed identity authentication (no passwords in code)
- ✅ HTTPS enforced via Container Apps ingress
- ✅ Soft delete enabled on Key Vault
- ⚠️ Storage Account uses access keys (consider upgrading to managed identity)
- ⚠️ Default network allows public access (consider VNet integration for production)

## Support

- **n8n Documentation:** https://docs.n8n.io/
- **Azure Container Apps:** https://learn.microsoft.com/azure/container-apps/
- **Issues:** Report issues in this repository

## License

This deployment configuration is provided as-is. n8n is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).
