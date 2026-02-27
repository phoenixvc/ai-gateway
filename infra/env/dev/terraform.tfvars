env            = "dev"
projname        = "aigateway"
location        = "southafricanorth"
location_short  = "san"

# Your Azure OpenAI endpoint host
# Placeholder value, will be overridden by environment variable or should be set by user
azure_openai_endpoint = "https://mys-shared-ai-swc.cognitiveservices.azure.com"

codex_model       = "gpt-5.3-codex"
codex_api_version = "2025-04-01-preview"

embedding_deployment   = "text-embedding-3-large"
embeddings_api_version = "2023-05-15"

# Rotate before expiration; extend or run rotation job per ops runbook
secrets_expiration_date = "2027-03-31T00:00:00Z"

tags = {
  owner    = "J"
  project  = "aigateway"
  env      = "dev"
}
