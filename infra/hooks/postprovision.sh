#!/bin/bash
# Post-Provision Hook for n8n on Azure (macOS/Linux)
# This script automatically configures the WEBHOOK_URL environment variable
# after the initial deployment completes

set -e

echo "🔧 Configuring n8n WEBHOOK_URL..."

# Navigate to azd's Terraform state directory
cd .azure/${AZURE_ENV_NAME}/infra

# Retrieve Container App name and Resource Group from Terraform outputs
N8N_APP_NAME=$(terraform output -raw n8n_container_app_name)
RG_NAME=$(terraform output -raw resource_group_name)

echo "📡 Retrieving n8n Container App URL..."
N8N_FQDN=$(az containerapp show \
  --name "$N8N_APP_NAME" \
  --resource-group "$RG_NAME" \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv)

if [ -z "$N8N_FQDN" ]; then
  echo "❌ Error: Could not retrieve Container App FQDN"
  exit 1
fi

echo "✅ n8n URL: https://$N8N_FQDN"

echo "🔄 Updating WEBHOOK_URL environment variable..."
az containerapp update \
  --name "$N8N_APP_NAME" \
  --resource-group "$RG_NAME" \
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN" \
  --output none

echo "✅ WEBHOOK_URL configured successfully!"
echo ""
echo "🎉 n8n deployment complete!"
echo "🌐 Access n8n at: https://$N8N_FQDN"
echo ""
echo "🔑 Login credentials:"
echo "   Username: $(terraform output -raw n8n_basic_auth_user)"
echo "   Password: (from your main.tfvars.json)"
echo ""
echo "⚠️  Important: Save your encryption key securely:"
echo "   Run: cd .azure/${AZURE_ENV_NAME}/infra && terraform output -raw n8n_encryption_key"
echo ""
