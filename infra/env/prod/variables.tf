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
