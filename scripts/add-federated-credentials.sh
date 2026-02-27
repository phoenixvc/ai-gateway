#!/bin/bash
set -e

# --- Add Federated Credentials for GitHub Actions Environments ---
# Use this script if you already ran bootstrap and got AADSTS700213 because
# the workflow uses environment: dev/uat/prod but Azure only had branch-based credentials.
#
# Usage: $0 <AZURE_CLIENT_ID> <GITHUB_ORG> <GITHUB_REPO>
# Example: $0 abc123-def456 phoenixvc ai-gateway

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <AZURE_CLIENT_ID> <GITHUB_ORG> <GITHUB_REPO>"
    echo ""
    echo "Adds federated identity credentials for dev, uat, prod environments"
    echo "to an existing Azure AD app registration (fixes AADSTS700213)."
    echo ""
    echo "Example: $0 \$(az ad app list --display-name pvc-github-actions-oidc --query [0].appId -o tsv) phoenixvc ai-gateway"
    exit 1
fi

APP_ID="$1"
GITHUB_ORG="$2"
GITHUB_REPO="$3"

OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv 2>/dev/null || {
    echo "Error: Could not find app with ID $APP_ID. Ensure you're logged in (az login) and the app exists."
    exit 1
})

echo "Adding federated credentials for environments (dev, uat, prod) to app $APP_ID..."
for ENV in dev uat prod; do
  SUBJECT="repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENV"
  echo "  Adding credential for environment: $ENV (subject: $SUBJECT)"
  az ad app federated-credential create --id "$OBJECT_ID" --parameters "{\"name\":\"github-actions-$ENV\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"$SUBJECT\",\"description\":\"GitHub Actions OIDC for $ENV environment\",\"audiences\":[\"api://AzureADTokenExchange\"]}" 2>/dev/null || {
    echo "  (Credential github-actions-$ENV may already exist; skipping)"
  }
done

echo ""
echo "Done. Re-run your GitHub Actions workflow."
