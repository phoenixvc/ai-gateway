terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

module "aigateway" {
  source = "../../modules/aigateway_aca"

  env           = var.env
  projname      = var.projname
  location      = var.location
  location_short= var.location_short
  tags          = var.tags

  azure_openai_endpoint   = var.azure_openai_endpoint
  azure_openai_api_key    = var.azure_openai_api_key

  gateway_key             = var.gateway_key

  codex_model             = var.codex_model
  codex_api_version       = var.codex_api_version

  embedding_deployment    = var.embedding_deployment
  embeddings_api_version  = var.embeddings_api_version

  ingress_external        = var.ingress_external
  min_replicas            = var.min_replicas
  max_replicas            = var.max_replicas
  secrets_expiration_date = var.secrets_expiration_date
}

output "gateway_url" {
  value = module.aigateway.gateway_url
}
