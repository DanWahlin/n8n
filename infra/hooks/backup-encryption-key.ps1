#Requires -Version 7.0

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Backing up n8n encryption key to Key Vault" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Get the absolute path to the infra directory
$ScriptDir = Split-Path -Parent $PSCommandPath
$InfraDir = Split-Path -Parent $ScriptDir

# Change to infra directory to run terraform commands
Set-Location $InfraDir

Write-Host "Retrieving Key Vault name..." -ForegroundColor Yellow
$KeyVaultName = terraform output -raw key_vault_name 2>&1

if (-not $KeyVaultName) {
    Write-Host "Error: Could not retrieve Key Vault name from Terraform outputs" -ForegroundColor Red
    exit 1
}

Write-Host "Retrieving n8n encryption key..." -ForegroundColor Yellow
$N8nEncryptionKey = terraform output -raw n8n_encryption_key 2>$null

if (-not $N8nEncryptionKey -or $N8nEncryptionKey -match "Warning|Error") {
    Write-Host "Error: Could not retrieve n8n encryption key from Terraform outputs" -ForegroundColor Red
    Write-Host "Output received: $N8nEncryptionKey" -ForegroundColor Red
    exit 1
}

Write-Host "Key Vault name: $KeyVaultName" -ForegroundColor Yellow
Write-Host "Storing encryption key in Key Vault..." -ForegroundColor Yellow

# Store the encryption key in Key Vault
try {
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name "n8n-encryption-key" `
        --value $N8nEncryptionKey `
        --output none 2>&1 | Out-Null
    
    Write-Host "✓ Successfully backed up n8n encryption key to Key Vault" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Failed to store encryption key in Key Vault, but continuing..." -ForegroundColor Yellow
    Write-Host "You can manually backup the key later using the commands in README.md" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "IMPORTANT: The encryption key has been stored in:" -ForegroundColor Yellow
Write-Host "  Key Vault: $KeyVaultName" -ForegroundColor White
Write-Host "  Secret Name: n8n-encryption-key" -ForegroundColor White
Write-Host ""
if (-not $KeyVaultName -or $KeyVaultName -match "Warning|Error") {
    Write-Host "Error: Could not retrieve Key Vault name from Terraform outputs" -ForegroundColor Red
    Write-Host "Output received: $KeyVaultName" -ForegroundColor Red
    exit 1
}

Write-Host "Retrieving n8n encryption key..." -ForegroundColor Yellow
$N8nEncryptionKey = terraform output -raw n8n_encryption_key 2>&1