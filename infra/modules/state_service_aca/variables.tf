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
}

variable "state_key_prefix" {
  type        = string
  description = "Namespace prefix for state keys"
  default     = "aigw:state"
}
