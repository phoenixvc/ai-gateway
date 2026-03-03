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

b64() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

export GATEWAY_URL_B64="$(b64 "${GATEWAY_URL:-}")"
export GRAFANA_URL_B64="$(b64 "${GRAFANA_URL:-}")"
export ENV_NAME_B64="$(b64 "${ENV_NAME:-}")"
export STATE_SERVICE_URL_B64="$(b64 "${STATE_SERVICE_URL:-}")"
json_payload=$(printf '{"GATEWAY_URL":"%s","GRAFANA_URL":"%s","ENV_NAME":"%s","STATE_SERVICE_URL":"%s"}' "$GATEWAY_URL_B64" "$GRAFANA_URL_B64" "$ENV_NAME_B64" "$STATE_SERVICE_URL_B64")
export CONFIG_JSON_B64="$(b64 "$json_payload")"

envsubst '$CONFIG_JSON_B64' \
  < /usr/share/nginx/html/index.html.template \
  > /usr/share/nginx/html/index.html

echo "Dashboard HTML generated successfully."
