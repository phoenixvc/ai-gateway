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
  prefix            = "pvc-${var.env}-${var.projname}"
  ca_name           = "${local.prefix}-state-${var.location_short}"
  use_registry_auth = var.registry_username != "" && var.registry_password != ""
  use_shared_token  = trimspace(var.state_service_shared_token) != ""

  tags = merge({
    env     = var.env
    project = var.projname
  }, var.tags)
}

resource "azurerm_container_app" "state_service" {
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
    for_each = local.use_registry_auth ? [1] : []
    content {
      name  = "registry-password"
      value = var.registry_password
    }
  }

  dynamic "secret" {
    for_each = local.use_shared_token ? [1] : []
    content {
      name  = "state-service-shared-token"
      value = var.state_service_shared_token
    }
  }

  dynamic "registry" {
    for_each = local.use_registry_auth ? [1] : []
    content {
      server               = var.registry_server
      username             = var.registry_username
      password_secret_name = "registry-password"
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "state-service"
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      liveness_probe {
        transport = "HTTP"
        path      = "/healthz"
        port      = 8080
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/healthz"
        port      = 8080
      }

      env {
        name  = "STATE_KEY_PREFIX"
        value = var.state_key_prefix
      }

      env {
        name  = "REDIS_URL"
        value = var.redis_url
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
    external_enabled = var.external_enabled
    target_port      = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
