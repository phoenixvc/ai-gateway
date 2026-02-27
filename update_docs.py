import re

with open('docs/Terraform_Blueprint.md', 'r') as f:
    content = f.read()

# 1. Add 'text' to the first code block (file tree)
if '```\ninfra/' in content:
    content = content.replace('```\ninfra/', '```text\ninfra/', 1)

# 2. Update litellm_config
old_config = r'''  litellm_config = <<-YAML
  model_list:
    - model_name: ${var.codex_model}
      litellm_params:
        model: azure/${var.codex_model}
        api_base: ${var.azure_openai_endpoint}/openai
        api_key: ${var.azure_openai_api_key}
        api_version: ${var.codex_api_version}
        # responses api
        # LiteLLM maps OpenAI-compatible surface to Azure responses when available

    - model_name: ${var.embedding_deployment}
      litellm_params:
        model: azure/${var.embedding_deployment}
        api_base: ${var.azure_openai_endpoint}
        api_key: ${var.azure_openai_api_key}
        api_version: ${var.embeddings_api_version}

  # Simple auth guard: require x-gateway-key (we implement via LiteLLM master key)
  # Many OpenAI-compatible tools send Authorization; Roo can send custom headers.
  # If you prefer Authorization bearer, swap enforcement accordingly.
  general_settings:
    # master_key works as a shared secret gate in LiteLLM
    master_key: ${var.gateway_key}
  YAML'''

new_config = r'''  litellm_config = <<-YAML
  model_list:
    - model_name: ${var.codex_model}
      litellm_params:
        model: azure/${var.codex_model}
        api_base: ${var.azure_openai_endpoint}/openai
        api_key: os.environ/LITELLM_AZURE_OPENAI_API_KEY
        api_version: ${var.codex_api_version}
        # responses api
        # LiteLLM maps OpenAI-compatible surface to Azure responses when available

    - model_name: ${var.embedding_deployment}
      litellm_params:
        model: azure/${var.embedding_deployment}
        api_base: ${var.azure_openai_endpoint}
        api_key: os.environ/LITELLM_AZURE_OPENAI_API_KEY
        api_version: ${var.embeddings_api_version}

  # Simple auth guard: require x-gateway-key (we implement via LiteLLM master key)
  # Many OpenAI-compatible tools send Authorization; Roo can send custom headers.
  # If you prefer Authorization bearer, swap enforcement accordingly.
  general_settings:
    # master_key works as a shared secret gate in LiteLLM
    master_key: os.environ/LITELLM_GATEWAY_KEY
  YAML'''

content = content.replace(old_config, new_config)

# 3. Update Container App env vars to include secrets
old_env = r'''      env {
        name  = "LITELLM_CONFIG"
        value = local.litellm_config
      }'''

new_env = r'''      env {
        name  = "LITELLM_CONFIG"
        value = local.litellm_config
      }

      env {
        name  = "LITELLM_AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-key"
      }

      env {
        name  = "LITELLM_GATEWAY_KEY"
        secret_name = "gateway-key"
      }'''

content = content.replace(old_env, new_env)

with open('docs/Terraform_Blueprint.md', 'w') as f:
    f.write(content)
