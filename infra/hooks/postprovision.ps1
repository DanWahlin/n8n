# Post-Provision Hook for n8n on Azure (Windows)
# This script automatically configures the WEBHOOK_URL environment variable
# after the initial deployment completes

$ErrorActionPreference = "Stop"

Write-Host "🔧 Configuring n8n WEBHOOK_URL..." -ForegroundColor Cyan

# Navigate to azd's Terraform state directory
Set-Location ".azure/$env:AZURE_ENV_NAME/infra"

# Retrieve Container App name and Resource Group from Terraform outputs
$N8N_APP_NAME = terraform output -raw n8n_container_app_name
$RG_NAME = terraform output -raw resource_group_name

# Get the Container App FQDN
Write-Host "📡 Retrieving n8n Container App URL..." -ForegroundColor Cyan
$N8N_FQDN = az containerapp show `
  --name $N8N_APP_NAME `
  --resource-group $RG_NAME `
  --query "properties.configuration.ingress.fqdn" `
  -o tsv

if ([string]::IsNullOrEmpty($N8N_FQDN)) {
  Write-Host "❌ Error: Could not retrieve Container App FQDN" -ForegroundColor Red
  exit 1
}

Write-Host "✅ n8n URL: https://$N8N_FQDN" -ForegroundColor Green

# Update the Container App with WEBHOOK_URL environment variable
Write-Host "🔄 Updating WEBHOOK_URL environment variable..." -ForegroundColor Cyan
az containerapp update `
  --name $N8N_APP_NAME `
  --resource-group $RG_NAME `
  --set-env-vars "WEBHOOK_URL=https://$N8N_FQDN" `
  --output none

Write-Host "✅ WEBHOOK_URL configured successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 n8n deployment complete!" -ForegroundColor Green
Write-Host "🌐 Access n8n at: https://$N8N_FQDN" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔑 Login credentials:" -ForegroundColor Yellow
$N8N_USER = terraform output -raw n8n_basic_auth_user
Write-Host "   Username: $N8N_USER" -ForegroundColor White
Write-Host "   Password: (from your main.tfvars.json)" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Important: Save your encryption key securely:" -ForegroundColor Yellow
Write-Host "   Run: cd .azure/$env:AZURE_ENV_NAME/infra && terraform output -raw n8n_encryption_key" -ForegroundColor White
Write-Host ""
