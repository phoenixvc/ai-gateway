import re

with open('infra/modules/aigateway_aca/main.tf', 'r') as f:
    content = f.read()

# 1. Pin versions
content = content.replace('required_version = ">= 1.6.0"', 'required_version = "~> 1.6.0"')
content = content.replace('version = ">= 3.90.0"', 'version = "~> 3.90.0"')

# 2. Update litellm_config
content = content.replace('api_key: ${var.azure_openai_api_key}', 'api_key: os.environ/LITELLM_AZURE_OPENAI_API_KEY')
content = content.replace('master_key: ${var.gateway_key}', 'master_key: os.environ/LITELLM_GATEWAY_KEY')

# 3. Update azurerm_key_vault
if 'network_acls' not in content:
    # We look for the closing brace of the resource block, but it's risky with regex spanning multiple lines
    # Instead, we insert it after 'tags = local.tags' which is at the end of the resource block in this file
    content = content.replace('tags = local.tags\n}', 'tags = local.tags\n\n  network_acls {\n    bypass         = "AzureServices"\n    default_action = "Deny"\n  }\n}')

# 4. Add access policy
if 'resource "azurerm_key_vault_access_policy" "terraform_client"' not in content:
    access_policy = """
resource "azurerm_key_vault_access_policy" "terraform_client" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}
"""
    # Insert before key vault secrets
    content = content.replace('# Store secrets in KV', access_policy + '\n# Store secrets in KV')

# 5. Add expiration_date to secrets
# Replace closing brace of secret resource with expiration_date
# We use a regex that matches the resource block up to the closing brace
content = re.sub(r'(resource "azurerm_key_vault_secret" "[^"]+" \{[^}]*value\s+=\s+var\.[^}]*)(\n\})', r'\1\n  expiration_date = var.secrets_expiration_date\2', content)


# 6. Update Container App secrets and env
# First, insert secrets into azurerm_container_app
if 'secret {' not in content:
    # Insert before template block
    secrets_block = """  secret {
    name  = "azure-openai-key"
    value = var.azure_openai_api_key
  }

  secret {
    name  = "gateway-key"
    value = var.gateway_key
  }

"""
    content = content.replace('template {', secrets_block + '  template {')

# Second, update env block
old_env = """      env {
        name  = "LITELLM_CONFIG"
        value = local.litellm_config
      }"""

new_env = """      env {
        name  = "LITELLM_CONFIG"
        value = local.litellm_config
      }

      env {
        name        = "LITELLM_AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-key"
      }

      env {
        name        = "LITELLM_GATEWAY_KEY"
        secret_name = "gateway-key"
      }"""

content = content.replace(old_env, new_env)

with open('infra/modules/aigateway_aca/main.tf', 'w') as f:
    f.write(content)
