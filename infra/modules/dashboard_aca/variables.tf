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
  description = "ID of the Container App Environment to deploy the dashboard into"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that owns the Container App Environment"
}

variable "container_image" {
  type        = string
  description = "Dashboard container image (e.g. ghcr.io/org/ai-gateway-dashboard:latest)"
}

variable "gateway_url" {
  type        = string
  description = "Full HTTPS URL of the AI Gateway, e.g. https://gateway.azurecontainerapps.io"
  validation {
    condition     = can(regex("^https://", var.gateway_url))
    error_message = "gateway_url must start with https://."
  }
}

variable "grafana_url" {
  type        = string
  description = "Grafana Cloud stack URL for the dashboard link button (leave empty to hide the button)"
  default     = ""
  validation {
    condition     = var.grafana_url == "" || can(regex("^https://", var.grafana_url))
    error_message = "grafana_url must be empty or start with https://."
  }
}

variable "state_service_url" {
  type        = string
  description = "Optional state service URL for shared model selection state (empty = local-only mode)"
  default     = ""
  validation {
    condition     = var.state_service_url == "" || can(regex("^https://", var.state_service_url))
    error_message = "state_service_url must be empty or start with https://."
  }
}
