FROM nginx:1.27-alpine

# Remove the default nginx config; our template replaces it.
RUN rm /etc/nginx/conf.d/default.conf

# Copy the nginx server-block template.
# nginx:1.19+ automatically runs envsubst on files in /etc/nginx/templates/
# when the container starts, writing results to /etc/nginx/conf.d/.
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Copy the HTML template.  A custom entrypoint script runs envsubst on it
# before nginx starts so that ${GATEWAY_URL}, ${GRAFANA_URL}, and ${ENV_NAME}
# are replaced with the Container App environment-variable values.
COPY index.html /usr/share/nginx/html/index.html.template

# Script: substitute placeholders in the HTML template, then hand off to the
# official nginx entrypoint which processes /etc/nginx/templates/*.template
# and finally starts nginx.
# NOTE: single quotes around the envsubst variable list are intentional —
# they prevent shell expansion so envsubst receives the literal variable
# names '$GATEWAY_URL $GRAFANA_URL $ENV_NAME' as its filter argument.
RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -e' \
    "envsubst '\$GATEWAY_URL \$GRAFANA_URL \$ENV_NAME' \\" \
    '  < /usr/share/nginx/html/index.html.template \' \
    '  > /usr/share/nginx/html/index.html' \
    > /docker-entrypoint.d/30-envsubst-html.sh \
  && chmod +x /docker-entrypoint.d/30-envsubst-html.sh

# Default values (overridden at runtime via Container App environment variables)
ENV GATEWAY_URL=""
ENV GRAFANA_URL=""
ENV ENV_NAME=""

EXPOSE 80
