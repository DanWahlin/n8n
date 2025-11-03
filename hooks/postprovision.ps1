# Post-provision script for Windows
Write-Host "Running post-provision setup..." -ForegroundColor Green

# Get the Key Vault name from Terraform outputs
Push-Location infra
$KEY_VAULT_NAME = terraform output -raw key_vault_name
Pop-Location

Write-Host "Key Vault: $KEY_VAULT_NAME"

# Check if the encryption key already exists
$secretExists = $false
try {
    az keyvault secret show --vault-name $KEY_VAULT_NAME --name "n8n-encryption-key" --output none 2>$null
    $secretExists = $LASTEXITCODE -eq 0
} catch {
    $secretExists = $false
}

if ($secretExists) {
    Write-Host "✓ Encryption key already exists in Key Vault" -ForegroundColor Green
} else {
    Write-Host "Generating N8N_ENCRYPTION_KEY..."
    
    # Generate a 32-character random encryption key
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
    $ENCRYPTION_KEY = [Convert]::ToBase64String($bytes).Replace("=", "").Replace("+", "").Replace("/", "").Substring(0, 32)
    
    Write-Host "Storing encryption key in Key Vault..."
    az keyvault secret set `
        --vault-name $KEY_VAULT_NAME `
        --name "n8n-encryption-key" `
        --value $ENCRYPTION_KEY `
        --output none
    
    Write-Host "✓ Encryption key generated and stored" -ForegroundColor Green
}

# Get outputs for user
Push-Location infra
$N8N_URL = terraform output -raw n8n_url
$RESOURCE_GROUP = terraform output -raw resource_group_name
Pop-Location

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "n8n Deployment Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "n8n URL: $N8N_URL" -ForegroundColor Yellow
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "Key Vault: $KEY_VAULT_NAME"
Write-Host ""
Write-Host "⚠️  Note: Container may take 2-3 minutes to start" -ForegroundColor Yellow
Write-Host "   Visit the URL above to access n8n"
Write-Host ""
Write-Host "To view logs:"
Write-Host "  az containerapp logs show --name <container-app-name> --resource-group $RESOURCE_GROUP --follow"
Write-Host ""
Write-Host "To view deployment status:"
Write-Host "  https://portal.azure.com/#@/resource/subscriptions/<subscription-id>/resourceGroups/$RESOURCE_GROUP"
Write-Host ""
