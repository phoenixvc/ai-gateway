FROM nginx:1.27-alpine

# Remove the default nginx config; our template replaces it.
RUN rm /etc/nginx/conf.d/default.conf

# Copy the nginx server-block template.
# nginx:1.19+ automatically runs envsubst on files in /etc/nginx/templates/
# when the container starts, writing results to /etc/nginx/conf.d/.
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Copy the HTML template.  The entrypoint script runs envsubst on it before
# nginx starts so that ${GATEWAY_URL}, ${GRAFANA_URL}, and ${ENV_NAME} are
# replaced with the Container App environment-variable values.
COPY index.html /usr/share/nginx/html/index.html.template

# Entrypoint script: validates GATEWAY_URL, runs envsubst on the HTML
# template, then hands off to the official nginx entrypoint.
COPY 30-envsubst-html.sh /docker-entrypoint.d/30-envsubst-html.sh
RUN chmod +x /docker-entrypoint.d/30-envsubst-html.sh

# Default values (overridden at runtime via Container App environment variables)
ENV GATEWAY_URL=""
ENV GRAFANA_URL=""
ENV ENV_NAME=""

EXPOSE 80
