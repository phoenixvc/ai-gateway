# Azure OIDC Setup for GitHub Actions

This repo uses **Azure OIDC** (OpenID Connect) for GitHub Actions authentication—no long-lived client secrets.

For the full list of required GitHub secrets (infrastructure + application), see [README § Add GitHub secrets](../README.md#2-add-github-secrets).

## AADSTS700213: No matching federated identity record found

If you see:

```
Error: AADSTS700213: No matching federated identity record found for presented assertion subject 'repo:phoenixvc/ai-gateway:environment:dev'
```

**Cause:** The workflow uses `environment: dev` (and uat/prod), so the OIDC subject is `repo:org/repo:environment:dev`. Azure must have a federated credential with that exact subject.

### Fix: Add environment federated credentials

If you already ran `bootstrap.sh` (which previously created only branch-based credentials), run:

```bash
./scripts/add-federated-credentials.sh <AZURE_CLIENT_ID> phoenixvc ai-gateway
```

To get `AZURE_CLIENT_ID` from an existing app:

```bash
az ad app list --display-name pvc-shared-github-actions-oidc --query "[0].appId" -o tsv
```

### Manual setup (Azure Portal)

1. Go to **Azure Portal** → **Microsoft Entra ID** → **App registrations** → your app (e.g. `pvc-shared-github-actions-oidc`)
2. **Certificates & secrets** → **Federated credentials** → **Add credential**
3. For each environment (dev, uat, prod), add:
   - **Federated credential scenario:** GitHub Actions deploying Azure resources
   - **Organization:** phoenixvc
   - **Repository:** ai-gateway
   - **Entity type:** Environment
   - **Environment name:** dev (or uat, prod)
   - **Name:** github-actions-dev (or uat, prod)

### Subject formats

| Workflow config | OIDC subject |
|-----------------|--------------|
| `environment: dev` | `repo:phoenixvc/ai-gateway:environment:dev` |
| `environment: uat` | `repo:phoenixvc/ai-gateway:environment:uat` |
| `environment: prod` | `repo:phoenixvc/ai-gateway:environment:prod` |
| Branch only (no env) | `repo:phoenixvc/ai-gateway:ref:refs/heads/main` |

The federated credential **Subject** in Azure must match exactly.
