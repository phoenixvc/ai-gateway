#!/bin/bash
set -e

# --- Usage Check ---
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <GITHUB_ORG> <GITHUB_REPO> [SCOPE]"
    echo "Example: $0 my-org my-repo   # defaults to subscription scope"
    exit 1
fi

GITHUB_ORG="$1"
GITHUB_REPO="$2"
SCOPE="$3"

# --- Configuration ---
# Shared infra: OIDC app and TF state span dev/uat/prod
LOCATION="southafricanorth"
RG_NAME="pvc-shared-tfstate-rg-san"
CONTAINER_NAME="tfstate"
APP_NAME="pvc-shared-github-actions-oidc"

# --- Determine Scope ---
if [ -z "$SCOPE" ]; then
    SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    SCOPE="/subscriptions/$SUBSCRIPTION_ID"
    echo "No scope provided. Defaulting to Subscription scope (required for creating resource groups): $SCOPE"
else
    echo "Using provided scope: $SCOPE"
fi


# --- Create Resource Group and Storage Account for Terraform State ---
echo "Creating Resource Group: $RG_NAME..."
az group create --name "$RG_NAME" --location "$LOCATION"

SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>/dev/null) || { echo "Error: Failed to get Azure subscription ID. Ensure you are logged in (az login)."; exit 1; }
EXISTING_SA=$(az storage account list --resource-group "$RG_NAME" --query "[?starts_with(name, 'pvctfstate')].name" -o tsv 2>/dev/null | head -n1)
if [ -n "$EXISTING_SA" ]; then
    SA_NAME="$EXISTING_SA"
    echo "Reusing existing Storage Account: $SA_NAME"
else
    SUFFIX=$(echo -n "$SUBSCRIPTION_ID" | openssl dgst -md5 2>/dev/null | awk '{print $NF}' | cut -c1-12)
    [ -z "$SUFFIX" ] && { echo "Error: Failed to compute deterministic suffix for storage account name."; exit 1; }
    SA_NAME="pvctfstate${SUFFIX}"
    echo "Creating Storage Account: $SA_NAME..."
    if ! az storage account create --resource-group "$RG_NAME" --name "$SA_NAME" --sku Standard_LRS --encryption-services blob 2>/dev/null; then
        if az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" &>/dev/null; then
            echo "Storage account $SA_NAME already exists, reusing."
        else
            echo "Error: Failed to create storage account $SA_NAME."
            exit 1
        fi
    fi
fi

unset AZURE_STORAGE_ACCOUNT AZURE_STORAGE_CONNECTION_STRING AZURE_STORAGE_KEY AZURE_STORAGE_SAS_TOKEN 2>/dev/null || true
STORAGE_CONN=$(az storage account show-connection-string --name "$SA_NAME" --resource-group "$RG_NAME" --query connectionString -o tsv 2>/dev/null)
if [ -z "$STORAGE_CONN" ]; then
    echo "Error: Failed to get connection string for storage account $SA_NAME."
    exit 1
fi
if az storage container show --name "$CONTAINER_NAME" --connection-string "$STORAGE_CONN" &>/dev/null; then
    echo "Reusing existing Storage Container: $CONTAINER_NAME"
else
    echo "Creating Storage Container: $CONTAINER_NAME..."
    if ! az storage container create --name "$CONTAINER_NAME" --connection-string "$STORAGE_CONN"; then
        if az storage container show --name "$CONTAINER_NAME" --connection-string "$STORAGE_CONN" &>/dev/null; then
            echo "Container $CONTAINER_NAME already exists, reusing."
        else
            echo "Error: Failed to create storage container $CONTAINER_NAME."
            exit 1
        fi
    fi
fi

# --- Create or reuse Azure AD Application and Service Principal for GitHub Actions OIDC ---
APP_MATCHES=($(az ad app list --display-name "$APP_NAME" --query "[].appId" -o tsv 2>/dev/null))
APP_COUNT=${#APP_MATCHES[@]}
if [ "$APP_COUNT" -gt 1 ]; then
  echo "Error: Multiple Azure AD applications found with display-name '$APP_NAME'. Resolve ambiguity manually."
  exit 1
fi
if [ "$APP_COUNT" -eq 1 ]; then
  APP_ID="${APP_MATCHES[0]}"
  echo "Reusing existing Azure AD Application: $APP_NAME ($APP_ID)"
else
  echo "Creating Azure AD Application: $APP_NAME..."
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)
  if [ -z "$APP_ID" ]; then
    echo "Error: Failed to create Azure AD application $APP_NAME."
    exit 1
  fi
fi

SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null)
if [ -n "$SP_ID" ]; then
  echo "Reusing existing Service Principal: $APP_NAME ($SP_ID)"
else
  echo "Creating Service Principal for App: $APP_ID..."
  SP_ID=$(az ad sp create --id "$APP_ID" --query id --output tsv)
  if [ -z "$SP_ID" ]; then
    echo "Error: Failed to create Service Principal for app $APP_ID."
    exit 1
  fi
fi

EXISTING_ROLE=$(az role assignment list --assignee-object-id "$SP_ID" --scope "$SCOPE" --role "Contributor" --query "[0].id" -o tsv 2>/dev/null)
if [ -n "$EXISTING_ROLE" ]; then
  echo "Role Assignment (Contributor) already exists on scope: $SCOPE"
else
  echo "Creating Role Assignment (Contributor) on scope: $SCOPE..."
  if ! az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal --role "Contributor" --scope "$SCOPE"; then
    echo "Error: Failed to assign Contributor role to SP on scope $SCOPE."
    exit 1
  fi
fi

OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv)

AIGATEWAY_KEY=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)

echo "Ensuring Federated Credentials for GitHub Actions (environments: dev, uat, prod)..."
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required for safe JSON construction. Install jq and retry."; exit 1; }
for ENV in dev uat prod; do
  SUBJECT="repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENV"
  EXISTING_SUBJECT=$(az ad app federated-credential list --id "$OBJECT_ID" --query "[?name=='github-actions-$ENV'].subject" -o tsv 2>/dev/null | head -n1)
  if [ -n "$EXISTING_SUBJECT" ] && [ "$EXISTING_SUBJECT" = "$SUBJECT" ]; then
    echo "  Federated credential for $ENV already exists with correct subject, skipping."
  else
    if [ -n "$EXISTING_SUBJECT" ] && [ "$EXISTING_SUBJECT" != "$SUBJECT" ]; then
      echo "  Federated credential for $ENV has stale subject, deleting and recreating."
      az ad app federated-credential delete --id "$OBJECT_ID" --federated-credential-id "github-actions-$ENV" 2>/dev/null || true
    fi
    echo "  Adding federated credential for environment: $ENV (subject: $SUBJECT)"
    FC_JSON=$(jq -n \
      --arg name "github-actions-$ENV" \
      --arg issuer "https://token.actions.githubusercontent.com" \
      --arg subject "$SUBJECT" \
      --arg desc "GitHub Actions OIDC for $ENV environment" \
      '{name: $name, issuer: $issuer, subject: $subject, description: $desc, audiences: ["api://AzureADTokenExchange"]}')
    az ad app federated-credential create --id "$OBJECT_ID" --parameters "$FC_JSON"
  fi
done

echo ""
echo "======================================================================"
echo "BOOTSTRAP COMPLETE! Please add the following secrets to your GitHub Repo:"
echo "======================================================================"
echo "Infrastructure Secrets:"
echo "  TF_BACKEND_RG:        $RG_NAME"
echo "  TF_BACKEND_SA:        $SA_NAME"
echo "  TF_BACKEND_CONTAINER: $CONTAINER_NAME"
echo "  AZURE_CLIENT_ID:      $APP_ID"
echo "  AZURE_TENANT_ID:      $(az account show --query tenantId --output tsv)"
echo "  AZURE_SUBSCRIPTION_ID: $(az account show --query id --output tsv)"
echo ""
echo "Application Secrets (Required for Deployment):"
echo "  AZURE_OPENAI_ENDPOINT: <Your Azure OpenAI Endpoint, e.g., https://mys-shared-ai-san.openai.azure.com/>"
echo "  AZURE_OPENAI_API_KEY:  <Your Azure OpenAI API Key>"
echo "  AIGATEWAY_KEY:         $AIGATEWAY_KEY"
echo "======================================================================"
