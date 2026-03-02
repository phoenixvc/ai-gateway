env            = "prod"
projname       = "aigateway"
location       = "southafricanorth"
location_short = "san"

# Production Azure OpenAI endpoint host.
# This value is overridden at runtime by the TF_VAR_azure_openai_endpoint
# environment variable (set via GitHub Environment secret AZURE_OPENAI_ENDPOINT).
# Do NOT use the UAT/shared endpoint here in production.
azure_openai_endpoint = "https://mys-prod-ai-san.cognitiveservices.azure.com"

codex_model = "gpt-4o"
# codex_api_version_reason: Preview required for gpt-4o responses API; monitor Azure docs for GA. Switch to stable when available.
codex_api_version = "2025-01-01-preview"

embedding_deployment   = "text-embedding-3-large"
embeddings_api_version = "2024-02-01"

# Rotate before expiration; alerting/rotation job must reference this. See ops runbook.
secrets_expiration_date = "2027-03-31T00:00:00Z"

tags = {
  owner   = "ai-gateway-team"
  project = "aigateway"
  env     = "prod"
}
