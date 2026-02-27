# Bootstrap script - PowerShell equivalent of bootstrap.sh
param(
    [Parameter(Mandatory=$true)] [string]$GITHUB_ORG,
    [Parameter(Mandatory=$true)] [string]$GITHUB_REPO,
    [Parameter(Mandatory=$false)] [string]$SCOPE
)

$ErrorActionPreference = "Stop"

$LOCATION = "southafricanorth"
$RG_NAME = "pvc-shared-tfstate-rg-san"
$CONTAINER_NAME = "tfstate"
$APP_NAME = "pvc-shared-github-actions-oidc"

$SUBSCRIPTION_ID = az account show --query id --output tsv 2>$null
if (-not $SUBSCRIPTION_ID) { Write-Error "Failed to get Azure subscription ID. Ensure you are logged in (az login)."; exit 1 }

if (-not $SCOPE) {
    $SCOPE = "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
    Write-Host "No scope provided. Defaulting to Resource Group scope: $SCOPE"
} else {
    Write-Host "Using provided scope: $SCOPE"
}

Write-Host "Creating Resource Group: $RG_NAME..."
az group create --name $RG_NAME --location $LOCATION
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create resource group $RG_NAME in $LOCATION. Exit code: $LASTEXITCODE"
    exit 1
}

$EXISTING_SA = az storage account list --resource-group $RG_NAME --query "[?starts_with(name, 'pvctfstate')].name" -o tsv 2>$null | Select-Object -First 1
if ($EXISTING_SA) {
    $SA_NAME = $EXISTING_SA
    Write-Host "Reusing existing Storage Account: $SA_NAME"
} else {
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($SUBSCRIPTION_ID))).Replace("-","").ToLower().Substring(0,12)
    $SA_NAME = "pvctfstate$hash"
    Write-Host "Creating Storage Account: $SA_NAME..."
    $createResult = az storage account create --resource-group $RG_NAME --name $SA_NAME --sku Standard_LRS --encryption-services blob 2>&1
    if ($LASTEXITCODE -ne 0) {
        $showResult = az storage account show --name $SA_NAME --resource-group $RG_NAME 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Host "Storage account $SA_NAME already exists, reusing." }
        else { Write-Error "Failed to create storage account $SA_NAME."; exit 1 }
    }
}

$null = az storage container show --name $CONTAINER_NAME --account-name $SA_NAME 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Reusing existing Storage Container: $CONTAINER_NAME"
} else {
    Write-Host "Creating Storage Container: $CONTAINER_NAME..."
    az storage container create --name $CONTAINER_NAME --account-name $SA_NAME
    if ($LASTEXITCODE -ne 0) {
        $null = az storage container show --name $CONTAINER_NAME --account-name $SA_NAME 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Container $CONTAINER_NAME already exists, reusing."
        } else {
            Write-Error "Failed to create storage container $CONTAINER_NAME. Ensure you have access to the storage account."
            exit 1
        }
    }
}

$EXISTING_APP = az ad app list --display-name $APP_NAME --query "[0].appId" -o tsv 2>$null
if ($EXISTING_APP) {
    $APP_ID = $EXISTING_APP
    Write-Host "Reusing existing Azure AD Application: $APP_NAME ($APP_ID)"
} else {
    Write-Host "Creating Azure AD Application: $APP_NAME..."
    $APP_ID = az ad app create --display-name $APP_NAME --query appId --output tsv
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($APP_ID)) {
        Write-Error "Failed to create Azure AD application $APP_NAME. az ad app create failed or returned empty appId."
        exit 1
    }
}

$EXISTING_SP = az ad sp list --display-name $APP_NAME --query "[0].id" -o tsv 2>$null
if ($EXISTING_SP) {
    $SP_ID = $EXISTING_SP
    Write-Host "Reusing existing Service Principal: $APP_NAME ($SP_ID)"
} else {
    Write-Host "Creating Service Principal for App: $APP_ID..."
    $SP_ID = az ad sp create --id $APP_ID --query id --output tsv
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($SP_ID)) {
        Write-Error "Failed to create Service Principal for app $APP_ID. az ad sp create failed or returned empty id."
        exit 1
    }
}

$EXISTING_ROLE = az role assignment list --assignee $SP_ID --scope $SCOPE --role "Contributor" --query "[0].id" -o tsv 2>$null
if ($EXISTING_ROLE) {
    Write-Host "Role Assignment (Contributor) already exists on scope: $SCOPE"
} else {
    Write-Host "Creating Role Assignment (Contributor) on scope: $SCOPE..."
    az role assignment create --assignee $SP_ID --role "Contributor" --scope $SCOPE
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to assign Contributor role to SP $SP_ID on scope $SCOPE. Exit code: $LASTEXITCODE"
        exit 1
    }
}

$OBJECT_ID = az ad app show --id $APP_ID --query id --output tsv

Write-Host "Ensuring Federated Credentials for GitHub Actions (environments: dev, uat, prod)..."
foreach ($ENV in @("dev","uat","prod")) {
    $SUBJECT = "repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENV"
    $EXISTING_FC = az ad app federated-credential list --id $OBJECT_ID --query "[?name=='github-actions-$ENV'].name" -o tsv 2>$null | Select-Object -First 1
    if ($EXISTING_FC) {
        Write-Host "  Federated credential for $ENV already exists, skipping."
    } else {
        Write-Host "  Adding federated credential for environment: $ENV (subject: $SUBJECT)"
        $params = @{
            name        = "github-actions-$ENV"
            issuer      = "https://token.actions.githubusercontent.com"
            subject     = $SUBJECT
            description = "GitHub Actions OIDC for $ENV environment"
            audiences   = @("api://AzureADTokenExchange")
        } | ConvertTo-Json
        az ad app federated-credential create --id $OBJECT_ID --parameters $params
    }
}

$AZURE_TENANT_ID = az account show --query tenantId --output tsv
Write-Host ""
Write-Host "======================================================================"
Write-Host "BOOTSTRAP COMPLETE! Please add the following secrets to your GitHub Repo:"
Write-Host "======================================================================"
Write-Host "Infrastructure Secrets:"
Write-Host "  TF_BACKEND_RG:        $RG_NAME"
Write-Host "  TF_BACKEND_SA:        $SA_NAME"
Write-Host "  TF_BACKEND_CONTAINER: $CONTAINER_NAME"
Write-Host "  AZURE_CLIENT_ID:      $APP_ID"
Write-Host "  AZURE_TENANT_ID:      $AZURE_TENANT_ID"
Write-Host "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
Write-Host ""
Write-Host "Application Secrets (Required for Deployment):"
Write-Host "  AZURE_OPENAI_ENDPOINT: <Your Azure OpenAI Endpoint, e.g., https://my-resource.openai.azure.com/>"
Write-Host "  AZURE_OPENAI_API_KEY:  <Your Azure OpenAI API Key>"
Write-Host "  AIGATEWAY_KEY:         <A strong random string for your Gateway Auth>"
Write-Host "======================================================================"
