#!/bin/bash
set -e

# --- Usage Check ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <GITHUB_ORG> <GITHUB_REPO>"
    echo "Example: $0 my-org my-repo"
    exit 1
fi

GITHUB_ORG="$1"
GITHUB_REPO="$2"

# --- Configuration ---
LOCATION="southafricanorth"
RG_NAME="pvc-tfstate-rg-san"
SA_NAME="pvctfstatest$RANDOM"
CONTAINER_NAME="tfstate"
APP_NAME="pvc-github-actions-oidc"

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
SP_ID=$(az ad sp create-for-rbac --name "$APP_NAME" --role "Contributor" --scopes "/subscriptions/$(az account show --query id --output tsv)" --query appId --output tsv)
OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv)

echo "Creating Federated Credential for GitHub Actions..."
az ad app federated-credential create --id "$OBJECT_ID" --parameters "{\"name\":\"github-actions-main\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",\"description\":\"GitHub Actions OIDC for main branch\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

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
