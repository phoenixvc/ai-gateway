with open('infra/env/dev/main.tf', 'r') as f:
    content = f.read()

content = content.replace('ingress_external        = true', 'ingress_external        = var.ingress_external')
content = content.replace('min_replicas            = 0', 'min_replicas            = var.min_replicas')
content = content.replace('max_replicas            = 3', 'max_replicas            = var.max_replicas')

# Add secrets_expiration_date
content = content.replace('max_replicas            = var.max_replicas', 'max_replicas            = var.max_replicas\n  secrets_expiration_date = var.secrets_expiration_date')

with open('infra/env/dev/main.tf', 'w') as f:
    f.write(content)
