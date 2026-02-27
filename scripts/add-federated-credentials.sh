#!/bin/bash
set -e

# Add Federated Credentials for GitHub Actions Environments
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
    echo "Example: $0 \$(az ad app list --display-name pvc-shared-github-actions-oidc --query [0].appId -o tsv) phoenixvc ai-gateway"
    exit 1
fi

APP_ID="$1"
GITHUB_ORG="$2"
GITHUB_REPO="$3"

OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv 2>/dev/null || {
    echo "Error: Could not find app with ID $APP_ID. Ensure you're logged in (az login) and the app exists."
    exit 1
})

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required for safe JSON construction. Install jq and retry."; exit 1; }

echo "Ensuring federated credentials for environments (dev, uat, prod) on app $APP_ID..."
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
echo "Done. Re-run your GitHub Actions workflow."
