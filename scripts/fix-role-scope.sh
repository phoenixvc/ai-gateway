#!/bin/bash
set -e

# One-time fix: Grant Contributor at subscription scope so Terraform can create
# resource groups (e.g. pvc-dev-aigateway-rg-san). Use this if bootstrap was run
# with the old default (RG scope) and apply fails with 403 on resource group creation.
#
# Usage: $0 [APP_NAME]
# Example: $0 pvc-shared-github-actions-oidc

APP_NAME="${1:-pvc-shared-github-actions-oidc}"

echo "fix-role-scope: Granting Contributor at subscription scope for Terraform resource group creation."
echo ""
echo "fix-role-scope: Looking up app '$APP_NAME'..."
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>&1) || true
if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
  echo "Error: App '$APP_NAME' not found. Ensure you're logged in (az login)."
  exit 1
fi
if [[ "$APP_ID" == *"ERROR"* ]] || [[ "$APP_ID" == *"error"* ]] || [[ "$APP_ID" == *"Login"* ]] || [[ "$APP_ID" == *"login"* ]]; then
  echo "Error: az ad app list failed: $APP_ID"
  exit 1
fi
echo "  App ID: $APP_ID"

echo "fix-role-scope: Looking up Service Principal..."
SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv 2>&1) || true
if [ -z "$SP_ID" ] || [[ "$SP_ID" == *"ERROR"* ]] || [[ "$SP_ID" == *"error"* ]]; then
  echo "Error: Service Principal for app $APP_ID not found. az output: $SP_ID"
  exit 1
fi
echo "  SP Object ID: $SP_ID"

echo "fix-role-scope: Getting subscription..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>&1) || true
if [ -z "$SUBSCRIPTION_ID" ] || [[ "$SUBSCRIPTION_ID" == *"ERROR"* ]] || [[ "$SUBSCRIPTION_ID" == *"error"* ]]; then
  echo "Error: Failed to get subscription ID. Run 'az login'. az output: $SUBSCRIPTION_ID"
  exit 1
fi
SCOPE="/subscriptions/$SUBSCRIPTION_ID"
echo "  Scope: $SCOPE"

echo "fix-role-scope: Checking existing role assignments..."
EXISTING=$(az role assignment list --assignee-object-id "$SP_ID" --scope "$SCOPE" --role "Contributor" --query "[0].id" -o tsv 2>/dev/null) || true
if [ -n "$EXISTING" ]; then
  echo "Contributor role already exists on subscription. No change needed."
  exit 0
fi

echo "fix-role-scope: Granting Contributor on $SCOPE to SP $SP_ID..."
if ! az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal --role "Contributor" --scope "$SCOPE"; then
  echo "Error: az role assignment create failed. You may need Owner/User Access Administrator to grant roles."
  exit 1
fi
echo "Done. Re-run your Terraform workflow."