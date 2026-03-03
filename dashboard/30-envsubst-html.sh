#!/bin/sh
# Substitutes ${GATEWAY_URL}, ${GRAFANA_URL}, ${ENV_NAME}, and
# ${STATE_SERVICE_URL} in the HTML
# template before nginx starts. This script is placed in /docker-entrypoint.d/
# so the official nginx entrypoint runs it automatically at container startup.
set -e

if [ -z "${GATEWAY_URL:-}" ]; then
  echo "ERROR: GATEWAY_URL environment variable is required but not set." >&2
  exit 1
fi

envsubst '$GATEWAY_URL $GRAFANA_URL $ENV_NAME $STATE_SERVICE_URL' \
  < /usr/share/nginx/html/index.html.template \
  > /usr/share/nginx/html/index.html

echo "Dashboard HTML generated successfully."
