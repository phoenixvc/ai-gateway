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
  default     = "2023-05-15"
}

# Optional scaling
variable "min_replicas" {
  type        = number
  default     = 0
}

variable "max_replicas" {
  type        = number
  default     = 3
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
