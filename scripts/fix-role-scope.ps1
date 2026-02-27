# One-time fix: Grant Contributor at subscription scope so Terraform can create
# resource groups (e.g. pvc-dev-aigateway-rg-san). Use this if bootstrap was run
# with the old default (RG scope) and apply fails with 403 on resource group creation.
#
# Usage: .\fix-role-scope.ps1 [APP_NAME]
# Example: .\fix-role-scope.ps1 pvc-shared-github-actions-oidc

param(
    [Parameter(Mandatory=$false)]
    [string]$AppName = "pvc-shared-github-actions-oidc"
)

$ErrorActionPreference = "Stop"

Write-Host "fix-role-scope: Granting Contributor at subscription scope for Terraform resource group creation."
Write-Host ""

Write-Host "fix-role-scope: Looking up app '$AppName'..."
$appId = az ad app list --display-name $AppName --query "[0].appId" -o tsv 2>$null
if ([string]::IsNullOrWhiteSpace($appId) -or $appId -eq "null") {
    Write-Error "App '$AppName' not found. Ensure you're logged in (az login)."
    exit 1
}
Write-Host "  App ID: $appId"

Write-Host "fix-role-scope: Looking up Service Principal..."
$spId = az ad sp show --id $appId --query id -o tsv 2>$null
if ([string]::IsNullOrWhiteSpace($spId)) {
    Write-Error "Service Principal for app $appId not found."
    exit 1
}
Write-Host "  SP Object ID: $spId"

Write-Host "fix-role-scope: Getting subscription..."
$subscriptionId = az account show --query id -o tsv 2>$null
if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
    Write-Error "Failed to get subscription ID. Run 'az login'."
    exit 1
}
$scope = "/subscriptions/$subscriptionId"
Write-Host "  Scope: $scope"

Write-Host "fix-role-scope: Setting subscription context..."
az account set --subscription $subscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription. Run 'az login' and 'az account set'."
    exit 1
}

Write-Host "fix-role-scope: Checking existing role assignments..."
$existing = az role assignment list --assignee-object-id $spId --scope $scope --role "Contributor" --query "[0].id" -o tsv 2>$null
if ($existing) {
    Write-Host "Contributor role already exists on subscription. No change needed."
    exit 0
}

Write-Host "fix-role-scope: Granting Contributor on $scope to SP $spId..."
az role assignment create --assignee-object-id $spId --assignee-principal-type ServicePrincipal --role "Contributor" --scope $scope
if ($LASTEXITCODE -ne 0) {
    Write-Error "az role assignment create failed. You may need Owner/User Access Administrator to grant roles."
    exit 1
}
Write-Host "Done. Re-run your Terraform workflow."
