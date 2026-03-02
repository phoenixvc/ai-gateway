# GitHub Secrets Checklist

Copy this checklist when setting up environments for this repo.

For workflow behavior (dev/uat/prod triggers, PR label `run-uat`, and smoke-test flow), see [CI_CD.md](CI_CD.md).

## Where to add secrets

Add these as **Environment secrets** in GitHub:

- **Settings → Environments → dev → Environment secrets**
- **Settings → Environments → uat → Environment secrets**
- **Settings → Environments → prod → Environment secrets**

> This workflow is environment-based (`environment: dev|uat|prod`), so each environment should have the full secret set.

## Required secrets (all environments)

- [ ] `AZURE_CLIENT_ID`
- [ ] `AZURE_TENANT_ID`
- [ ] `AZURE_SUBSCRIPTION_ID`
- [ ] `TF_BACKEND_RG`
- [ ] `TF_BACKEND_SA`
- [ ] `TF_BACKEND_CONTAINER`
- [ ] `AZURE_OPENAI_ENDPOINT`
- [ ] `AZURE_OPENAI_API_KEY`
- [ ] `AZURE_OPENAI_EMBEDDING_ENDPOINT` *(optional — set only if embeddings use a different Azure OpenAI resource)*
- [ ] `AZURE_OPENAI_EMBEDDING_API_KEY` *(optional — set only if embeddings use a different API key)*
- [ ] `AIGATEWAY_KEY`

## Copy/paste template

Use this block as a setup checklist when creating/updating `dev`, `uat`, and `prod`:

```text
AZURE_CLIENT_ID=<GUID>
AZURE_TENANT_ID=<GUID>
AZURE_SUBSCRIPTION_ID=<GUID>
TF_BACKEND_RG=<resource-group-name>
TF_BACKEND_SA=<storage-account-name>
TF_BACKEND_CONTAINER=tfstate
AZURE_OPENAI_ENDPOINT=https://<your-resource>.cognitiveservices.azure.com
AZURE_OPENAI_API_KEY=<key>
AZURE_OPENAI_EMBEDDING_ENDPOINT=                # optional: only if embeddings are on a different resource
AZURE_OPENAI_EMBEDDING_API_KEY=                 # optional: only if embeddings use a different key
AIGATEWAY_KEY=<gateway-key>
```

## Validation before deploy

- [ ] `AZURE_OPENAI_ENDPOINT` and `AZURE_OPENAI_API_KEY` are from the **same** Azure OpenAI resource.
- [ ] `AZURE_OPENAI_ENDPOINT` is base URL only (no `/openai/...` path).
- [ ] If embeddings live on a different Azure OpenAI resource, set `AZURE_OPENAI_EMBEDDING_ENDPOINT` (and optionally `AZURE_OPENAI_EMBEDDING_API_KEY`). Otherwise leave them blank to use the main endpoint.
- [ ] For `prod`, `AZURE_OPENAI_ENDPOINT` host is `mys-prod-ai-san.cognitiveservices.azure.com`.
- [ ] `AIGATEWAY_KEY` matches the key expected by the deployed gateway.
- [ ] OIDC federated credentials exist for each environment subject:
  - `repo:phoenixvc/ai-gateway:environment:dev`
  - `repo:phoenixvc/ai-gateway:environment:uat`
  - `repo:phoenixvc/ai-gateway:environment:prod`

## Runtime UAT toggle

- UAT deploy on PRs into `main` is controlled by PR label `run-uat`.
- Add label `run-uat` to enable `deploy-uat` for that PR.
- Remove label `run-uat` to skip UAT for that PR.

For OIDC troubleshooting, see [AZURE_OIDC_SETUP.md](AZURE_OIDC_SETUP.md).
