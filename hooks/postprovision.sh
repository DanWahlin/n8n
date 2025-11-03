#!/bin/bash
set -e

echo "Running post-provision setup..."

# Get the Key Vault name and encryption key from Terraform outputs
KEY_VAULT_NAME=$(cd infra && terraform output -raw key_vault_name)
ENCRYPTION_KEY=$(cd infra && terraform output -raw n8n_encryption_key)
echo "Key Vault: $KEY_VAULT_NAME"

# Store the encryption key in Key Vault for backup
echo "Storing encryption key in Key Vault for backup..."
if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "n8n-encryption-key" &>/dev/null; then
    echo "✓ Encryption key already exists in Key Vault"
else
    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "n8n-encryption-key" \
        --value "$ENCRYPTION_KEY" \
        --output none
    echo "✓ Encryption key stored in Key Vault"
fi

# Get outputs for user
N8N_URL=$(cd infra && terraform output -raw n8n_url)
RESOURCE_GROUP=$(cd infra && terraform output -raw resource_group_name)

echo ""
echo "============================================"
echo "n8n Deployment Complete!"
echo "============================================"
echo ""
echo "n8n URL: $N8N_URL"
echo "Resource Group: $RESOURCE_GROUP"
echo "Key Vault: $KEY_VAULT_NAME"
echo ""
echo "⚠️  Note: Container may take 2-3 minutes to start"
echo "   Visit the URL above to access n8n"
echo ""
echo "To view logs:"
echo "  az containerapp logs show --name <container-app-name> --resource-group $RESOURCE_GROUP --follow"
echo ""
echo "To view deployment status:"
echo "  https://portal.azure.com/#@/resource/subscriptions/<subscription-id>/resourceGroups/$RESOURCE_GROUP"
echo ""
