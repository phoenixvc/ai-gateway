terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.62.0"
    }
  }
}

locals {
  prefix           = "pvc-${var.env}-${var.projname}"
  ca_name          = "${local.prefix}-dashboard-${var.location_short}"
  use_shared_token = trim(var.state_service_shared_token) != ""

  tags = merge({
    env     = var.env
    project = var.projname
  }, var.tags)
}

resource "azurerm_container_app" "dashboard" {
  lifecycle {
    precondition {
      condition     = var.container_image != ""
      error_message = "container_image must not be empty."
    }
  }

  name                         = local.ca_name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = local.tags

  dynamic "secret" {
    for_each = local.use_shared_token ? [1] : []
    content {
      name  = "state-service-shared-token"
      value = var.state_service_shared_token
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "dashboard"
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      # Liveness probe: uses the /healthz endpoint served by nginx
      liveness_probe {
        transport = "HTTP"
        path      = "/healthz"
        port      = 80
      }

      # Readiness probe
      readiness_probe {
        transport = "HTTP"
        path      = "/healthz"
        port      = 80
      }

      env {
        name  = "GATEWAY_URL"
        value = var.gateway_url
      }

      env {
        name  = "GRAFANA_URL"
        value = var.grafana_url
      }

      env {
        name  = "ENV_NAME"
        value = var.env
      }

      env {
        name  = "STATE_SERVICE_URL"
        value = var.state_service_url
      }

      dynamic "env" {
        for_each = local.use_shared_token ? [1] : []
        content {
          name        = "STATE_SERVICE_SHARED_TOKEN"
          secret_name = "state-service-shared-token"
        }
      }

      dynamic "env" {
        for_each = local.use_shared_token ? [] : [1]
        content {
          name  = "STATE_SERVICE_SHARED_TOKEN"
          value = ""
        }
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
