# AGENTS.md - Guidance for AI Coding Agents

This file provides guidance for AI coding agents operating in this repository.

## Project Overview

**ai-gateway** — OpenAI-compatible AI gateway built on LiteLLM, deployed to Azure Container Apps. Routes `/v1/responses` and `/v1/embeddings` to Azure OpenAI.

### Tech Stack

- **Gateway**: LiteLLM (Python)
- **Dashboard**: Node.js/pnpm (in `dashboard/`)
- **Infrastructure**: Terraform (>= 1.14.0) in `infra/`
- **State Service**: Python/FastAPI in `state-service/`
- **Type Checking**: mypy
- **Scripts**: Deployment/setup scripts in `scripts/`

---

## Build / Lint / Test Commands

### Dashboard (Node.js/pnpm)

```bash
cd dashboard
pnpm install          # Install dependencies
pnpm dev              # Start dev server
pnpm format           # Format code with prettier
pnpm format:check    # Check formatting only
pnpm lint             # Run format check
```

### Python (State Service)

```bash
# Type checking
mypy .                # Run mypy on entire project

# Running a single Python test (if tests exist)
python -m pytest scripts/test_specific.py::TestClass::test_method

# Individual script execution
python scripts/integration_test.py
python scripts/check_aoai_embeddings.py
```

### Terraform (Infrastructure)

```bash
cd infra

# Initialize and plan
terraform init
terraform plan

# Format check
terraform fmt -check -recursive

# Apply
terraform apply
```

### Combined Checks

```bash
# Run all checks (format + terraform)
pnpm check
```

---

## Code Style Guidelines

### Python (state-service/)

**Imports**

- Use absolute imports within packages: `from .routes import router`
- Group imports: stdlib → third-party → local
- Use `import os`, `from typing import Optional`, etc.

**Formatting**

- Follow PEP 8
- Use 4 spaces for indentation
- Maximum line length: 100 characters

**Types (mypy)**

- Python version: 3.13 (see `mypy.ini`)
- Use type hints for function parameters and return values
- Run `mypy .` before committing

**Naming**

- Variables/functions: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Private members: prefix with `_`

**Error Handling**

- Use custom exceptions with descriptive names
- Catch specific exceptions, not bare `except:`
- Include context in error messages

```python
def selection_key(user_id: str) -> str:
    if not user_id or not user_id.strip():
        raise ValueError("user_id must be a non-empty string")
    # ...
```

### JavaScript (dashboard/)

**Formatting**

- Use Prettier for formatting (configured in `package.json`)
- Run `pnpm format` before committing

**Naming**

- Variables/functions: `camelCase`
- Constants: `UPPER_SNAKE_CASE` or `camelCase` with const
- Classes: `PascalCase`

**General JS Style**

- Use `const` by default, `let` when reassignment needed
- Prefer template literals over string concatenation
- Use strict equality (`===`) not loose equality (`==`)

```javascript
const MAX_POINTS = 20;
const reqHistory = { labels: [], datasets: [...] };
```

### Terraform (infra/)

**Formatting**

- Use `terraform fmt` to format files
- Run `terraform fmt -check -recursive` in CI

**Naming**

- Resources: `snake_case`
- Variables: `snake_case`
- Outputs: `snake_case`

**General**

- Use local values for repeated expressions
- Tag all resources with `env`, `project`
- Pin provider versions: `version = ">= 4.62.0"`

### GitHub Actions (`.github/workflows/`)

**Formatting**

- Use Prettier for YAML files
- Run `pnpm format` to format workflow files

**Naming**

- Job names: descriptive, lowercase with hyphens
- Step names: descriptive

### Documentation (docs/)

**Formatting**

- Use Prettier for Markdown files
- Run `pnpm format` to format docs

**General**

- Use ATX-style headers (`#`, `##`, etc.)
- Keep lines under 100 characters when practical
- Include code blocks with language identifiers

---

## Architecture Overview

```
docs/architecture/
├── systems/          # Individual system documentation
├── reference/        # Reference and planning docs
│   └── strategic/   # Strategic guidance
├── 01-*-*.md       # ADR-style documents

dashboard/           # Admin UI (Node.js/pnpm)
infra/              # Terraform IaC
scripts/            # Deployment automation
state-service/      # FastAPI state service
```

---

## Key Files

| File                                  | Purpose               |
| ------------------------------------- | --------------------- |
| `CLAUDE.md`                           | Claude Code guidance  |
| `dashboard/app.js`                    | Dashboard UI          |
| `infra/modules/aigateway_aca/main.tf` | Main infrastructure   |
| `state-service/state_service/`        | FastAPI state service |
| `.github/workflows/deploy.yaml`       | CI/CD pipeline        |

---

## Prerequisites

- Azure CLI (`az login`)
- Terraform >= 1.14.0
- Node.js + pnpm
- Python 3.13+

---

## Before Committing

1. Run formatting: `pnpm format`
2. Run type checks: `mypy .` (if Python changed)
3. Run terraform fmt: `terraform fmt -check -recursive`
4. Test locally if possible
