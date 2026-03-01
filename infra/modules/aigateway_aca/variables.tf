# Provider: Callers must configure the azurerm provider. This module does not
# declare a provider block so root modules can supply their own configuration.

variable "env" {
  type        = string
  description = "Environment name (dev|uat|prod)"
  validation {
    condition     = contains(["dev", "uat", "prod"], var.env)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "projname" {
  type        = string
  description = "Project name"
  default     = "aigateway"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "southafricanorth"
}

variable "location_short" {
  type        = string
  description = "Short location code"
  default     = "san"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

# LiteLLM container
variable "container_image" {
  type        = string
  description = "LiteLLM container image; use amd64 digest for Azure Container Apps (e.g. litellm/litellm:v1.81.15@sha256:...)"

}

variable "container_port" {
  type        = number
  description = "Container port for LiteLLM"
  default     = 4000
}

# Ingress
variable "ingress_external" {
  type        = bool
  description = "Whether ingress is external"
  default     = true
}

# Security: simple client->gateway auth
variable "gateway_key" {
  type        = string
  description = "Shared key clients must send as x-gateway-key"
  sensitive   = true
}

# Upstream Azure OpenAI
variable "azure_openai_endpoint" {
  type        = string
  description = "Azure OpenAI endpoint host, e.g. https://mys-shared-ai-swc.cognitiveservices.azure.com"
}

variable "azure_openai_api_key" {
  type        = string
  description = "Azure OpenAI API key"
  sensitive   = true
}

variable "azure_openai_embedding_endpoint" {
  type        = string
  description = "Azure OpenAI endpoint for embedding models. Defaults to azure_openai_endpoint if empty."
  default     = ""
  validation {
    condition     = var.azure_openai_embedding_endpoint == "" || can(regex("^https://", var.azure_openai_embedding_endpoint))
    error_message = "azure_openai_embedding_endpoint must be empty or start with https://."
  }
}

variable "azure_openai_embedding_api_key" {
  type        = string
  description = "Azure OpenAI API key for embedding endpoint. Defaults to azure_openai_api_key if empty."
  sensitive   = true
  default     = ""
}

variable "codex_model" {
  type        = string
  description = "Codex deployment/model name for responses"
  default     = "gpt-5.3-codex"
}

variable "codex_api_version" {
  type        = string
  description = "Responses API version"
  default     = "2025-04-01-preview"
}

variable "embedding_deployment" {
  type        = string
  description = "Embedding deployment name"
  default     = "text-embedding-3-large"
}

variable "embeddings_api_version" {
  type        = string
  description = "Embeddings API version"
  default     = "2024-02-01"
}

# Optional scaling
variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 3
}

variable "secrets_expiration_date" {
  type        = string
  description = "Expiration date for Key Vault secrets (ISO-8601 UTC format, e.g. 2026-12-31T00:00:00Z)"
}

variable "key_vault_network_default_action" {
  type        = string
  description = "Key Vault network ACL default action. Use Allow when deploying from GitHub Actions (external IPs); Deny for private-only access."
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_default_action)
    error_message = "Must be Allow or Deny."
  }
}

# Langfuse LLM observability (optional — leave empty to disable)
variable "langfuse_public_key" {
  type        = string
  description = "Langfuse public key. Leave empty to disable Langfuse tracing."
  default     = ""
}

variable "langfuse_secret_key" {
  type        = string
  description = "Langfuse secret key. Leave empty to disable Langfuse tracing."
  default     = ""
  sensitive   = true
}

variable "langfuse_host" {
  type        = string
  description = "Langfuse host URL for self-hosted deployments (e.g. https://langfuse.example.com). Leave empty for Langfuse Cloud."
  default     = ""
}

# Redis caching (optional — set to true to provision Azure Cache for Redis)
variable "enable_redis_cache" {
  type        = bool
  description = "Provision Azure Cache for Redis and configure LiteLLM to cache identical requests, reducing Azure OpenAI token spend."
  default     = false
}

variable "redis_cache_capacity" {
  type        = number
  description = "Azure Cache for Redis capacity (SKU unit). 0 = C0 (250 MB, dev/test); 1 = C1 (1 GB); 2 = C2 (6 GB). Increase for production workloads with higher request volumes."
  default     = 0
  validation {
    condition     = contains([0, 1, 2], var.redis_cache_capacity)
    error_message = "redis_cache_capacity must be one of: 0 (C0), 1 (C1), or 2 (C2) for this module."
  }
}

# Budget and rate limiting (0 / empty = disabled)
variable "max_budget" {
  type        = number
  description = "Global maximum spend in USD before the gateway starts rejecting requests (0 = no limit)."
  default     = 0
}

variable "budget_duration" {
  type        = string
  description = "How often the budget counter resets, e.g. '1d', '7d', '30d'. Empty = never reset."
  default     = ""
}

variable "rpm_limit" {
  type        = number
  description = "Global requests-per-minute cap across all API keys (0 = no limit)."
  default     = 0
}

variable "tpm_limit" {
  type        = number
  description = "Global tokens-per-minute cap across all API keys (0 = no limit)."
  default     = 0
}
