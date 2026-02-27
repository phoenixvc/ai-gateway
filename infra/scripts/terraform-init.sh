#!/bin/bash
# Load .env.local and run terraform init -upgrade
# Usage: ./infra/scripts/terraform-init.sh [dev|uat|prod]

set -e

ENV="${1:?Usage: $0 dev|uat|prod}"
case "$ENV" in
    dev|uat|prod) ;;
    *)
        echo "Usage: $0 dev|uat|prod"
        echo "Error: ENV must be dev, uat, or prod; got: $ENV"
        exit 1
        ;;
esac
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env.local not found. Copy infra/.env.local.example to infra/.env.local and fill in values."
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

missing=""
[ -z "$TF_BACKEND_RG" ] && missing="${missing}TF_BACKEND_RG "
[ -z "$TF_BACKEND_SA" ] && missing="${missing}TF_BACKEND_SA "
[ -z "$TF_BACKEND_CONTAINER" ] && missing="${missing}TF_BACKEND_CONTAINER "
if [ -n "$missing" ]; then
    echo "Error: Missing required backend variables: $missing"
    echo "Set them in infra/.env.local"
    exit 1
fi

cd "$SCRIPT_DIR/../env/$ENV"
terraform init -upgrade \
    -backend-config="resource_group_name=$TF_BACKEND_RG" \
    -backend-config="storage_account_name=$TF_BACKEND_SA" \
    -backend-config="container_name=$TF_BACKEND_CONTAINER" \
    -backend-config="key=$ENV.terraform.tfstate"
