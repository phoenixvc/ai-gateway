# Load .env.local and run terraform init -upgrade
# Usage: .\infra\scripts\terraform-init.ps1 [dev|uat|prod]

param([Parameter(Mandatory=$true)][ValidateSet("dev","uat","prod")][string]$Env)

$envFile = Join-Path $PSScriptRoot ".." ".env.local"
if (-not (Test-Path $envFile)) {
    Write-Error ".env.local not found. Copy infra/.env.local.example to infra/.env.local and fill in values."
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "Env:$name" -Value $value -Force
    }
}

$envDir = Join-Path $PSScriptRoot ".." "env" $Env
Push-Location $envDir
try {
    terraform init -upgrade `
        -backend-config="resource_group_name=$env:TF_BACKEND_RG" `
        -backend-config="storage_account_name=$env:TF_BACKEND_SA" `
        -backend-config="container_name=$env:TF_BACKEND_CONTAINER" `
        -backend-config="key=$Env.terraform.tfstate"
} finally {
    Pop-Location
}
