#!/bin/bash
set -e

echo "====================================="
echo "Backing up n8n encryption key to Key Vault"
echo "====================================="

# Get the absolute path to the infra directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to infra directory to run terraform commands
cd "$INFRA_DIR"

echo "Retrieving Key Vault name..."
KEY_VAULT_NAME=$(terraform output -raw key_vault_name 2>&1)

if [ -z "$KEY_VAULT_NAME" ]; then
    echo "Error: Could not retrieve Key Vault name from Terraform outputs"
    exit 1
fi

echo "Retrieving n8n encryption key..."
N8N_ENCRYPTION_KEY=$(terraform output -raw n8n_encryption_key 2>/dev/null)

if [ -z "$N8N_ENCRYPTION_KEY" ] || [[ "$N8N_ENCRYPTION_KEY" == *"Warning"* ]] || [[ "$N8N_ENCRYPTION_KEY" == *"Error"* ]]; then
    echo "Error: Could not retrieve n8n encryption key from Terraform outputs"
    echo "Output received: $N8N_ENCRYPTION_KEY"
    exit 1
fi

echo "Key Vault name: $KEY_VAULT_NAME"
echo "Storing encryption key in Key Vault..."

# Store the encryption key in Key Vault
if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "n8n-encryption-key" \
    --value "$N8N_ENCRYPTION_KEY" \
    --output none 2>&1; then
    echo "✓ Successfully backed up n8n encryption key to Key Vault"
else
    echo "Warning: Failed to store encryption key in Key Vault, but continuing..."
    echo "You can manually backup the key later using the commands in README.md"
fi
echo ""
echo "IMPORTANT: The encryption key has been stored in:"
echo "  Key Vault: $KEY_VAULT_NAME"
echo "  Secret Name: n8n-encryption-key"
if [ -z "$KEY_VAULT_NAME" ] || [[ "$KEY_VAULT_NAME" == *"Warning"* ]] || [[ "$KEY_VAULT_NAME" == *"Error"* ]]; then
    echo "Error: Could not retrieve Key Vault name from Terraform outputs"
    echo "Output received: $KEY_VAULT_NAME"
    exit 1
fi

echo "Retrieving n8n encryption key..."
N8N_ENCRYPTION_KEY=$(terraform output -raw n8n_encryption_key 2>&1)