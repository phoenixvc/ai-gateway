output "stack_id" {
  description = "Numeric ID of the Grafana Cloud stack."
  value       = grafana_cloud_stack.this.id
}

output "stack_url" {
  description = "Grafana Cloud stack URL (e.g. https://<slug>.grafana.net)."
  value       = grafana_cloud_stack.this.url
}

output "stack_slug" {
  description = "Slug of the Grafana Cloud stack."
  value       = grafana_cloud_stack.this.slug
}

output "prometheus_url" {
  description = "Prometheus endpoint URL; use this when configuring LiteLLM or Alloy to remote-write metrics."
  value       = grafana_cloud_stack.this.prometheus_url
}

output "github_actions_token" {
  description = "Service account token for GitHub Actions dashboard deployments. Copy this value to the GRAFANA_SA_TOKEN GitHub Actions secret."
  value       = grafana_cloud_stack_service_account_token.github_actions.key
  sensitive   = true
}

output "terraform_service_account_token" {
  description = "Service account token (Admin) for Terraform to manage stack resources. Store securely; not needed for dashboard-only workflows."
  value       = grafana_cloud_stack_service_account_token.terraform.key
  sensitive   = true
}
