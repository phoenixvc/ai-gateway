import sys

with open('scripts/bootstrap.sh', 'r') as f:
    content = f.read()

# 1. Update Usage
content = content.replace('if [ "$#" -ne 2 ]; then', 'if [ "$#" -lt 2 ]; then')
content = content.replace('echo "Usage: $0 <GITHUB_ORG> <GITHUB_REPO>"', 'echo "Usage: $0 <GITHUB_ORG> <GITHUB_REPO> [SCOPE]"')
content = content.replace('echo "Example: $0 my-org my-repo"', 'echo "Example: $0 my-org my-repo /subscriptions/xxxx/resourceGroups/my-rg"')
content = content.replace('GITHUB_ORG="$1"\nGITHUB_REPO="$2"', 'GITHUB_ORG="$1"\nGITHUB_REPO="$2"\nSCOPE="$3"')

# 2. Add Scope Logic
scope_logic = """
# --- Determine Scope ---
if [ -z "$SCOPE" ]; then
    SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
    echo "No scope provided. Defaulting to Resource Group scope: $SCOPE"
else
    echo "Using provided scope: $SCOPE"
fi
"""
content = content.replace('APP_NAME="pvc-github-actions-oidc"', 'APP_NAME="pvc-github-actions-oidc"\n' + scope_logic)

# 3. Update SP Creation logic
old_sp_block = """echo "Creating Azure AD Application: $APP_NAME..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)
SP_ID=$(az ad sp create-for-rbac --name "$APP_NAME" --role "Contributor" --scopes "/subscriptions/$(az account show --query id --output tsv)" --query appId --output tsv)
OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv)"""

new_sp_block = """echo "Creating Azure AD Application: $APP_NAME..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)

echo "Creating Service Principal for App: $APP_ID..."
SP_ID=$(az ad sp create --id "$APP_ID" --query id --output tsv)

echo "Creating Role Assignment (Contributor) on scope: $SCOPE..."
az role assignment create --assignee "$SP_ID" --role "Contributor" --scope "$SCOPE"

OBJECT_ID=$(az ad app show --id "$APP_ID" --query id --output tsv)"""

content = content.replace(old_sp_block, new_sp_block)

with open('scripts/bootstrap.sh', 'w') as f:
    f.write(content)
