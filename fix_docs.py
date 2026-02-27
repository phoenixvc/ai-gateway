with open('docs/Terraform_Blueprint.md', 'r') as f:
    content = f.read()

# Revert all ```text to ```
content = content.replace('```text', '```')

# Apply the first change again correctly
content = content.replace('```\ninfra/', '```text\ninfra/', 1)

with open('docs/Terraform_Blueprint.md', 'w') as f:
    f.write(content)
