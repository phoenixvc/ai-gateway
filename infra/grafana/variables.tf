variable "grafana_cloud_access_policy_token" {
  type        = string
  description = "Grafana Cloud access policy token. Generate at https://grafana.com/profile/api-keys with scopes: stacks:read, stacks:write, stack-service-accounts:read, stack-service-accounts:write."
  sensitive   = true
}

variable "stack_name" {
  type        = string
  description = "Display name for the Grafana Cloud stack (e.g. 'PVC AI Gateway')."
}

variable "stack_slug" {
  type        = string
  description = "Unique URL slug for the Grafana Cloud stack (e.g. 'pvc-aigateway'). The stack will be reachable at https://<slug>.grafana.net."
}

variable "region_slug" {
  type        = string
  description = "Grafana Cloud region slug. Common values: 'prod-us-central-0', 'prod-eu-west-0', 'prod-ap-southeast-0'."
  default     = "prod-us-central-0"
}
