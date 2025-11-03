# Plan: Deploy n8n to Azure (Development with SQLite & Terraform)

**Last Updated:** November 3, 2025

## Overview

Deploy n8n workflow automation platform to Azure using Container Apps with SQLite database for maximum cost savings (~$3-5/month), using Terraform managed by Azure Developer CLI with local state, eliminating external database costs while maintaining functionality for development workflows.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Azure Container Apps Environment          │
│  ┌──────────────────────────────────────┐  │
│  │ n8n Container                        │  │
│  │ - Image: docker.n8n.io/n8nio/n8n    │  │
│  │ - Port: 5678                         │  │
│  │ - Volume: /home/node/.n8n (SQLite)   │  │
│  │ - Scale: 0-3 replicas                │  │
│  │ - Resources: 0.5 vCPU, 1GB RAM       │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
         │                    │
         │                    └─────> Azure Monitor
         │                            (Log Analytics)
         │
         └─────> Azure Key Vault
                 (N8N_ENCRYPTION_KEY)
```

## Implementation Steps

### Step 1: Create Terraform Infrastructure Modules

Build the following Terraform files in the `infra/` directory:

**`infra/main.tf`**
- Configure Azure provider (azurerm)
- Create resource group
- Create Container Apps environment
- Reference other modules (keyvault, container-app, monitoring)

**`infra/container-app.tf`**
- Define Container App resource
- Configure n8n container image (`docker.n8n.io/n8nio/n8n:latest`)
- Set up persistent volume mount to `/home/node/.n8n` for SQLite storage
- Configure environment variables (Key Vault references)
- Set ingress configuration (external, port 5678, HTTP/HTTPS)
- Configure scale rules (min: 0, max: 3)
- Set resource limits (0.5 vCPU, 1GB memory)

**`infra/keyvault.tf`**
- Create Azure Key Vault
- Configure access policies for Container App managed identity
- Enable soft delete and purge protection
- Set up RBAC for secret access

**`infra/monitoring.tf`**
- Create Log Analytics workspace
- Configure Container App logging integration
- Set up basic alert rules for container failures

**`infra/variables.tf`**
- Define input variables:
  - `location` (default: "eastus")
  - `environment_name` (default: "dev")
  - `resource_group_name`
  - `n8n_image_tag` (default: "latest")

**`infra/outputs.tf`**
- Export Container App FQDN
- Export Key Vault name
- Export resource group name
- Export n8n URL (https://{fqdn})

### Step 2: Configure Azure Developer CLI

**`azure.yaml`**
- Set project name: "n8n-azure"
- Configure infrastructure provider: `type: terraform`
- Define local state management
- Set hooks for post-provisioning
- Configure services section (if needed for future extensions)

**`infra/terraform.tfvars.json`**
- Environment-specific values:
  ```json
  {
    "location": "eastus",
    "environment_name": "dev",
    "n8n_image_tag": "latest"
  }
  ```

**`.gitignore`**
- Add Terraform artifacts:
  - `.terraform/`
  - `*.tfstate`
  - `*.tfstate.backup`
  - `.terraform.lock.hcl`
- Add Azure CLI artifacts:
  - `.azure/`
  - `.env`

### Step 3: Set up n8n with SQLite Configuration

**`.env.sample`**
Create sample environment file with required variables:
```bash
# n8n Configuration
N8N_PORT=5678
N8N_PROTOCOL=https
GENERIC_TIMEZONE=America/New_York
TZ=America/New_York
NODE_ENV=production
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Database (SQLite - default, no config needed)
# DB_TYPE defaults to SQLite when not specified

# Encryption (stored in Key Vault)
# N8N_ENCRYPTION_KEY will be set from Key Vault reference

# Optional: Metrics
# N8N_METRICS=true
```

**`hooks/postprovision.sh`**
- Generate `N8N_ENCRYPTION_KEY` (32 random characters)
- Store encryption key in Azure Key Vault using Azure CLI
- Set up managed identity permissions
- Output deployment information (URL, Key Vault name)

**Container App Environment Variables**
Configure in Terraform using Key Vault references:
- `N8N_ENCRYPTION_KEY` → Key Vault secret reference
- `N8N_HOST` → Container App FQDN
- `WEBHOOK_URL` → https://{FQDN}
- Standard environment variables from `.env.sample`

### Step 4: Apply Terraform Best Practices

Retrieve Azure Terraform best practices using the best practices tool and apply:

**Resource Organization**
- Use consistent naming conventions (e.g., `rg-n8n-dev-eastus`)
- Group related resources with locals
- Use data sources for existing resources

**Security**
- Never hardcode secrets in Terraform
- Use managed identities instead of service principals
- Enable diagnostic settings on all resources
- Use private endpoints where applicable (future enhancement)

**State Management**
- Use local state (azd-managed)
- Add `.terraform/` to `.gitignore`
- Document state location in README

**Cost Optimization**
- Set `min_replicas = 0` for scale-to-zero
- Use consumption-based pricing tier
- Configure appropriate resource limits
- Document cost breakdown

**Dependencies**
- Use `depends_on` for explicit resource ordering
- Ensure Key Vault exists before Container App
- Ensure managed identity has Key Vault access before deployment

### Step 5: Add Monitoring and Health Checks

**Health Probe Configuration**
In `infra/container-app.tf`:
- HTTP liveness probe pointing to `/healthz`
- Probe interval: 30 seconds
- Failure threshold: 3
- Timeout: 5 seconds

**Log Analytics Integration**
- Send container logs to Log Analytics workspace
- Enable stdout/stderr capture
- Configure log retention (30 days for dev)

**Basic Alerts**
- Container restart count > 5 in 10 minutes
- Container availability < 100%
- HTTP 5xx errors > 10 in 5 minutes

**Metrics Endpoint**
- Document n8n `/metrics` endpoint availability
- Note: Requires `N8N_METRICS=true` environment variable
- Can be scraped by Azure Monitor or Prometheus

### Step 6: Create Deployment Documentation

**`README.md`**

Include the following sections:

1. **Prerequisites**
   - Azure subscription
   - Azure CLI installed and authenticated
   - Azure Developer CLI (azd) installed
   - Terraform installed (version 1.5+)
   - Docker (for local testing)

2. **Quick Start**
   ```bash
   # Clone repository
   git clone <repo-url>
   cd n8n
   
   # Login to Azure
   az login
   
   # Deploy infrastructure and application
   azd up
   ```

3. **Architecture Overview**
   - Component diagram
   - Service descriptions
   - Data flow

4. **Configuration**
   - Environment variables reference
   - SQLite data persistence location
   - Volume mount details
   - How to customize settings

5. **Cost Breakdown**
   - Container Apps: ~$2-3/month (with scale-to-zero)
   - Key Vault: ~$0.50/month (10,000 operations)
   - Log Analytics: ~$0-1/month (500MB free tier)
   - **Total: ~$3-5/month**

6. **Local Testing**
   ```bash
   # Test n8n locally with Docker
   docker run -d \
     --name n8n \
     -p 5678:5678 \
     -v ~/.n8n:/home/node/.n8n \
     docker.n8n.io/n8nio/n8n
   ```

7. **Migration to Production**
   - When to migrate from SQLite to PostgreSQL
   - Steps to add Azure Database for PostgreSQL
   - Data migration considerations
   - Cost implications (~$12-15/month additional)

8. **Troubleshooting**
   - Container won't start → Check logs in Azure Portal
   - Can't access n8n → Verify ingress configuration
   - Data persistence issues → Check volume mount
   - Encryption key errors → Verify Key Vault access

9. **Commands Reference**
   ```bash
   # Deploy/update
   azd up
   
   # View logs
   azd monitor --logs
   
   # Destroy infrastructure
   azd down
   
   # Access n8n URL
   azd show
   ```

## Open Questions

### 1. Volume Size for SQLite
**Question:** 1GB sufficient for development or allocate 5GB?

**Options:**
- **1GB** - Adequate for basic workflows, testing, and small automation
  - Pros: Lower cost, faster provisioning
  - Cons: May need expansion if heavily used
  
- **5GB** - Better headroom for extensive testing
  - Pros: Won't need resize, supports more workflows
  - Cons: Slightly higher cost (minimal)

**Recommendation:** Start with 1GB, can be increased later if needed. Azure Container Apps volumes can be resized without data loss.

## Success Criteria

Deployment is successful when:
- [ ] Infrastructure deploys without errors via `azd up`
- [ ] n8n web UI is accessible at Container App URL
- [ ] Can create and execute a test workflow
- [ ] Workflow data persists after container restart
- [ ] Logs are visible in Log Analytics
- [ ] Total monthly cost is under $5
- [ ] Container scales to zero after 10 minutes of inactivity
- [ ] Documentation is complete and accurate

## Future Enhancements

Potential improvements for production migration:
1. Migrate to Azure Database for PostgreSQL Flexible Server
2. Add Azure Cache for Redis for queue mode
3. Configure custom domain with SSL certificate
4. Implement VNet integration and private endpoints
5. Add Azure Storage for binary data
6. Set up CI/CD pipeline for automated deployments
7. Configure backup and disaster recovery
8. Implement multi-region deployment
9. Add Azure Front Door for global distribution
10. Set up comprehensive monitoring dashboards

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss on container deletion | High | Volume persists independently; document backup procedures |
| SQLite limitations at scale | Medium | Plan migration to PostgreSQL; document triggers |
| Cost overruns | Low | Scale-to-zero enabled; monitor Azure Cost Management |
| Security vulnerabilities | Medium | Use Key Vault for secrets; enable managed identity |
| Container image updates | Low | Pin to specific version tag; test before updating |

## Timeline Estimate

- **Infrastructure setup:** 2-3 hours
- **Configuration and testing:** 1-2 hours
- **Documentation:** 1 hour
- **Total:** ~4-6 hours

## References

- n8n Documentation: https://docs.n8n.io/
- Azure Container Apps: https://learn.microsoft.com/azure/container-apps/
- Azure Developer CLI: https://learn.microsoft.com/azure/developer/azure-developer-cli/
- Terraform Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
