#!/bin/bash
set -e

# --- Usage Check ---
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <GITHUB_ORG> <GITHUB_REPO> [SCOPE]"
    echo "Example: $0 my-org my-repo /subscriptions/xxxx/resourceGroups/my-rg"
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
    SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
    echo "No scope provided. Defaulting to Resource Group scope: $SCOPE"
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
    SA_NAME="pvctfstatest${SUFFIX}"
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

echo "Creating Storage Container: $CONTAINER_NAME..."
if ! az storage container create --name "$CONTAINER_NAME" --account-name "$SA_NAME" 2>/dev/null; then
    if az storage container show --name "$CONTAINER_NAME" --account-name "$SA_NAME" &>/dev/null; then
        echo "Container $CONTAINER_NAME already exists, reusing."
    else
        echo "Error: Failed to create storage container $CONTAINER_NAME."
        exit 1
    fi
fi

# --- Create Azure AD Application and Service Principal for GitHub Actions OIDC ---
echo "Creating Azure AD Application: $APP_NAME..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)

echo "Creating Service Principal for App: $APP_ID..."
SP_ID=$(az ad sp create --id "$APP_ID" --query id --output tsv)

echo "Creating Role Assignment (Contributor) on scope: $SCOPE..."
az role assignment create --assignee "$SP_ID" --role "Contributor" --scope "$SCOPE"

OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv)

echo "Creating Federated Credentials for GitHub Actions (environments: dev, uat, prod)..."
for ENV in dev uat prod; do
  SUBJECT="repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENV"
  echo "  Adding federated credential for environment: $ENV (subject: $SUBJECT)"
  az ad app federated-credential create --id "$OBJECT_ID" --parameters "{\"name\":\"github-actions-$ENV\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"$SUBJECT\",\"description\":\"GitHub Actions OIDC for $ENV environment\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
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
echo "  AZURE_OPENAI_API_BASE: <Your Azure OpenAI Endpoint, e.g., https://my-resource.openai.azure.com/>"
echo "  AZURE_OPENAI_API_KEY:  <Your Azure OpenAI API Key>"
echo "  AIGATEWAY_KEY:         <A strong random string for your Gateway Auth>"
echo "======================================================================"
