env            = "uat"
projname       = "aigateway"
location       = "southafricanorth"
location_short = "san"

# Your Azure OpenAI endpoint host.
# NOTE: The TF_VAR_azure_openai_endpoint environment variable (set via the
# GitHub Environment secret AZURE_OPENAI_ENDPOINT) takes precedence over this
# value during CI/CD runs. For local development, either set that env var or
# update this file with the correct UAT endpoint.
azure_openai_endpoint = "https://mys-shared-ai-swc.cognitiveservices.azure.com"

codex_model       = "gpt-5.3-codex"
codex_api_version = "2025-04-01-preview"

embedding_deployment   = "text-embedding-3-large"
embeddings_api_version = "2023-05-15"

# Rotate before expiration; CI workflow or alert must notify owners. See secrets_expiration_date in runbook.
secrets_expiration_date = "2027-03-31T00:00:00Z"

tags = {
  owner   = "ai-gateway-team"
  project = "aigateway"
  env     = "uat"
}
