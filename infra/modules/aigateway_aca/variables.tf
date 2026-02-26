variable "env" {
  type        = string
  description = "Environment name (dev|uat|prod)"
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
  description = "LiteLLM container image"
  default     = "ghcr.io/berriai/litellm:latest"
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
