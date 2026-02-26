variable "env" { type = string }
variable "location" { type = string }
variable "location_short" { type = string }
variable "projname" { type = string }

variable "azure_openai_endpoint" { type = string }
variable "azure_openai_api_key" { type = string sensitive = true }

variable "gateway_key" { type = string sensitive = true }

variable "codex_model" { type = string }
variable "codex_api_version" { type = string }

variable "embedding_deployment" { type = string }
variable "embeddings_api_version" { type = string }

variable "tags" { type = map(string) }
