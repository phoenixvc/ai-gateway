import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
bootstrap_path = os.path.join(script_dir, 'scripts', 'bootstrap.sh')

with open(bootstrap_path, 'r') as f:
    content = f.read()

# 1. Update Usage
# Handle two possible initial states: original (-ne 2) or previously-patched (-lt 2 only).
content = content.replace('if [ "$#" -ne 2 ]; then', 'if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then')
content = content.replace('if [ "$#" -lt 2 ]; then', 'if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then')
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
anchor = 'APP_NAME="pvc-github-actions-oidc"'
new_content = content.replace(anchor, anchor + '\n' + scope_logic)
if new_content == content:
    raise RuntimeError(f"Replacement anchor not found: {anchor!r}")
content = new_content

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

with open(bootstrap_path, 'w') as f:
    f.write(content)
