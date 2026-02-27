import re

with open('infra/modules/aigateway_aca/variables.tf', 'r') as f:
    content = f.read()

# 1. Update container_image to remove default
content = content.replace('  default     = "ghcr.io/berriai/litellm:latest"', '')
content = content.replace('description = "LiteLLM container image"', 'description = "LiteLLM container image (e.g. ghcr.io/berriai/litellm:v1.34.0)"')

# 2. Add validation for env
env_validation = """variable "env" {
  type        = string
  description = "Environment name (dev|uat|prod)"
  validation {
    condition     = contains(["dev", "uat", "prod"], var.env)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}"""
content = re.sub(r'variable "env" \{\s+type\s+=\s+string\s+description\s+=\s+"Environment name \(dev\|uat\|prod\)"\s+\}', env_validation, content, flags=re.DOTALL)

# 3. Add secrets_expiration_date variable
secrets_exp_var = """
variable "secrets_expiration_date" {
  type        = string
  description = "Expiration date for Key Vault secrets (ISO-8601 UTC format, e.g. 2026-12-31T00:00:00Z)"
}
"""
content += secrets_exp_var

with open('infra/modules/aigateway_aca/variables.tf', 'w') as f:
    f.write(content)
