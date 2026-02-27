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

Remove-Item Env:AZURE_STORAGE_ACCOUNT -ErrorAction SilentlyContinue
Remove-Item Env:AZURE_STORAGE_CONNECTION_STRING -ErrorAction SilentlyContinue
Remove-Item Env:AZURE_STORAGE_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AZURE_STORAGE_SAS_TOKEN -ErrorAction SilentlyContinue

$STORAGE_CONN = az storage account show-connection-string --name $SA_NAME --resource-group $RG_NAME --query connectionString -o tsv 2>$null
if (-not $STORAGE_CONN) {
    Write-Error "Failed to get connection string for storage account $SA_NAME."
    exit 1
}

$null = az storage container show --name $CONTAINER_NAME --connection-string $STORAGE_CONN 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Reusing existing Storage Container: $CONTAINER_NAME"
} else {
    Write-Host "Creating Storage Container: $CONTAINER_NAME..."
    az storage container create --name $CONTAINER_NAME --connection-string $STORAGE_CONN
    if ($LASTEXITCODE -ne 0) {
        $null = az storage container show --name $CONTAINER_NAME --connection-string $STORAGE_CONN 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Container $CONTAINER_NAME already exists, reusing."
        } else {
            Write-Error "Failed to create storage container $CONTAINER_NAME."
            exit 1
        }
    }
}

$appMatches = @(az ad app list --display-name $APP_NAME --query "[].appId" -o tsv 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($appMatches.Count -gt 1) {
    Write-Error "Multiple Azure AD applications found with display-name '$APP_NAME'. Resolve ambiguity manually."
    exit 1
}
if ($appMatches.Count -eq 1) {
    $APP_ID = $appMatches[0].Trim()
    Write-Host "Reusing existing Azure AD Application: $APP_NAME ($APP_ID)"
} else {
    Write-Host "Creating Azure AD Application: $APP_NAME..."
    $APP_ID = az ad app create --display-name $APP_NAME --query appId --output tsv
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($APP_ID)) {
        Write-Error "Failed to create Azure AD application $APP_NAME. az ad app create failed or returned empty appId."
        exit 1
    }
}

$SP_ID = az ad sp show --id $APP_ID --query id -o tsv 2>$null
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($SP_ID)) {
    Write-Host "Reusing existing Service Principal: $APP_NAME ($SP_ID)"
} else {
    Write-Host "Creating Service Principal for App: $APP_ID..."
    $SP_ID = az ad sp create --id $APP_ID --query id --output tsv
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($SP_ID)) {
        Write-Error "Failed to create Service Principal for app $APP_ID. az ad sp create failed or returned empty id."
        exit 1
    }
}

$EXISTING_ROLE = az role assignment list --assignee-object-id $SP_ID --scope $SCOPE --role "Contributor" --query "[0].id" -o tsv 2>$null
if ($EXISTING_ROLE) {
    Write-Host "Role Assignment (Contributor) already exists on scope: $SCOPE"
} else {
    Write-Host "Creating Role Assignment (Contributor) on scope: $SCOPE..."
    az role assignment create --assignee-object-id $SP_ID --assignee-principal-type ServicePrincipal --role "Contributor" --scope $SCOPE
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to assign Contributor role to SP $SP_ID on scope $SCOPE. Exit code: $LASTEXITCODE"
        exit 1
    }
}

$OBJECT_ID = az ad app show --id $APP_ID --query id --output tsv

$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$AIGATEWAY_KEY = [Convert]::ToBase64String($bytes)

Write-Host "Ensuring Federated Credentials for GitHub Actions (environments: dev, uat, prod)..."
foreach ($EnvName in @("dev","uat","prod")) {
    $SUBJECT = "repo:" + $GITHUB_ORG + "/" + $GITHUB_REPO + ":environment:" + $EnvName
    $EXISTING_SUBJECT = az ad app federated-credential list --id $OBJECT_ID --query "[?name=='github-actions-$EnvName'].subject" -o tsv 2>$null | Select-Object -First 1
    if ($EXISTING_SUBJECT -and ($EXISTING_SUBJECT -eq $SUBJECT)) {
        Write-Host "  Federated credential for $EnvName already exists with correct subject, skipping."
    } else {
        if ($EXISTING_SUBJECT -and ($EXISTING_SUBJECT -ne $SUBJECT)) {
            Write-Host "  Federated credential for $EnvName has stale subject, deleting and recreating."
            az ad app federated-credential delete --id $OBJECT_ID --federated-credential-id "github-actions-$EnvName" 2>$null
        }
        Write-Host "  Adding federated credential for environment: $EnvName (subject: $SUBJECT)"
        $params = @{
            name        = "github-actions-$EnvName"
            issuer      = "https://token.actions.githubusercontent.com"
            subject     = $SUBJECT
            description = "GitHub Actions OIDC for $EnvName environment"
            audiences   = @("api://AzureADTokenExchange")
        } | ConvertTo-Json -Compress
        $paramsFile = [System.IO.Path]::GetTempFileName()
        $params | Set-Content -Path $paramsFile -Encoding UTF8 -NoNewline
        try {
            az ad app federated-credential create --id $OBJECT_ID --parameters "@$paramsFile"
        } finally {
            Remove-Item $paramsFile -Force -ErrorAction SilentlyContinue
        }
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
Write-Host "  AZURE_OPENAI_ENDPOINT: <Your Azure OpenAI Endpoint, e.g., https://mys-shared-ai-san.openai.azure.com/>"
Write-Host "  AZURE_OPENAI_API_KEY:  <Your Azure OpenAI API Key>"
Write-Host "  AIGATEWAY_KEY:         $AIGATEWAY_KEY"
Write-Host "======================================================================"
