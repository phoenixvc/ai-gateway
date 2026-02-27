variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.env)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}
variable "location" { type = string }
variable "location_short" { type = string }
variable "projname" { type = string }

variable "azure_openai_endpoint" {
  type = string
  validation {
    condition     = length(var.azure_openai_endpoint) > 0 && can(regex("^https://", var.azure_openai_endpoint))
    error_message = "Azure OpenAI endpoint must start with https:// and not be empty."
  }
}
variable "azure_openai_api_key" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.azure_openai_api_key) > 0
    error_message = "Azure OpenAI API key must not be empty."
  }
}

variable "gateway_key" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.gateway_key) > 0
    error_message = "Gateway key must not be empty."
  }
}

variable "container_image" {
  type        = string
  description = "LiteLLM container image (use amd64 digest for Azure Container Apps)"
  default     = "litellm/litellm:v1.81.15@sha256:d104dae60f1a0c8fc93f837ec30ec4e6430ee70b0d3636874c26bc9920ae34a7"
}

variable "codex_model" { type = string }
variable "codex_api_version" { type = string }

variable "embedding_deployment" { type = string }
variable "embeddings_api_version" { type = string }

variable "tags" { type = map(string) }

variable "ingress_external" {
  type    = bool
  default = true
}

variable "min_replicas" {
  type    = number
  default = 1
  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 100
    error_message = "min_replicas must be between 0 and 100."
  }
}

variable "max_replicas" {
  type    = number
  default = 3
  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 100
    error_message = "max_replicas must be between 1 and 100."
  }
}

variable "secrets_expiration_date" {
  type        = string
  description = "Expiration date for Key Vault secrets (ISO-8601 UTC format, e.g. 2026-12-31T00:00:00Z)"
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.secrets_expiration_date)) && can(formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", var.secrets_expiration_date)) && can(timecmp(var.secrets_expiration_date, "1970-01-01T00:00:00Z")) && timecmp(var.secrets_expiration_date, plantimestamp()) > 0
    error_message = "secrets_expiration_date must be in ISO-8601 UTC format and strictly in the future relative to plan time."
  }
}
