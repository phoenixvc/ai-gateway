variable "stack_name" {
  type        = string
  description = "Display name for the Grafana Cloud stack (e.g. 'PVC AI Gateway')."
}

variable "stack_slug" {
  type        = string
  description = "Unique URL slug for the Grafana Cloud stack; lowercase alphanumeric and hyphens only (e.g. 'pvc-aigateway')."
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.stack_slug))
    error_message = "stack_slug must be lowercase alphanumeric characters and hyphens, 2–63 characters long."
  }
}

variable "region_slug" {
  type        = string
  description = "Grafana Cloud region slug. Common values: 'prod-us-central-0', 'prod-eu-west-0', 'prod-ap-southeast-0'."
  default     = "prod-us-central-0"
}
