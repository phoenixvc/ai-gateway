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
SA_NAME="pvctfstatest$RANDOM"
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

echo "Creating Storage Account: $SA_NAME..."
az storage account create --resource-group "$RG_NAME" --name "$SA_NAME" --sku Standard_LRS --encryption-services blob

echo "Creating Storage Container: $CONTAINER_NAME..."
az storage container create --name "$CONTAINER_NAME" --account-name "$SA_NAME"

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
