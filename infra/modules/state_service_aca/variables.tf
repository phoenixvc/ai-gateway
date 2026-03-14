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

variable "location_short" {
  type        = string
  description = "Short location code (e.g. san)"
  default     = "san"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

variable "container_app_environment_id" {
  type        = string
  description = "ID of the Container App Environment"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "container_image" {
  type        = string
  description = "State service container image"
}

variable "redis_url" {
  type        = string
  description = "Optional Redis URL (empty = in-memory store)"
  default     = ""
  sensitive   = true
}

variable "state_key_prefix" {
  type        = string
  description = "Namespace prefix for state keys"
  default     = "aigw:state"
}

variable "state_service_shared_token" {
  type        = string
  description = "Optional shared token required from trusted proxy"
  default     = ""
  sensitive   = true
}

variable "external_enabled" {
  type        = bool
  description = "Whether state-service ingress should be externally accessible"
  default     = false
}

variable "registry_server" {
  type        = string
  description = "Container registry server for state-service image pulls"
  default     = "ghcr.io"
}

variable "registry_username" {
  type        = string
  description = "Optional container registry username for private image pulls"
  default     = ""
}

variable "registry_password" {
  type        = string
  description = "Optional container registry password/token for private image pulls"
  default     = ""
  sensitive   = true
}
