terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}

# Grafana Cloud stack for the AI Gateway project.
resource "grafana_cloud_stack" "this" {
  name        = var.stack_name
  slug        = var.stack_slug
  region_slug = var.region_slug
}

# Service account used by Terraform to manage resources within the stack (Admin).
resource "grafana_cloud_stack_service_account" "terraform" {
  stack_slug = grafana_cloud_stack.this.slug
  name       = "terraform-deployer"
  role       = "Admin"
}

resource "grafana_cloud_stack_service_account_token" "terraform" {
  stack_slug         = grafana_cloud_stack.this.slug
  name               = "terraform-token"
  service_account_id = grafana_cloud_stack_service_account.terraform.id
}

# Service account used by GitHub Actions to deploy dashboards (Editor).
resource "grafana_cloud_stack_service_account" "github_actions" {
  stack_slug = grafana_cloud_stack.this.slug
  name       = "github-actions-deployer"
  role       = "Editor"
}

resource "grafana_cloud_stack_service_account_token" "github_actions" {
  stack_slug         = grafana_cloud_stack.this.slug
  name               = "github-actions-token"
  service_account_id = grafana_cloud_stack_service_account.github_actions.id
}
