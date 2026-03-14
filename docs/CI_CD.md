# CI/CD Runbook

This document describes the current GitHub Actions deployment behavior for `ai-gateway`.

## Workflow summary

- PRs from forks are skipped for deployment-related jobs (no repo secrets).
- PRs targeting `dev` run `plan` + `deploy-dev`.
- PRs targeting `main` run UAT only when the PR has label `run-uat`.
- Push to `main` and `workflow_dispatch` run `plan` + `deploy-prod`.

## Runtime UAT toggle

UAT deployment for PRs to `main` is controlled by PR label:

- Add label `run-uat` to enable `deploy-uat` for that PR.
- Remove label `run-uat` to disable UAT for that PR.

## Smoke test behavior

The composite action `.github/actions/smoke-test-gateway` performs:

- `GET /v1/models` diagnostics.
- `POST /v1/embeddings` and `POST /v1/responses` with retries.
- Candidate probing for embeddings if the requested model fails.
- Azure OpenAI deployment discovery fallback using configured endpoint/key when needed.

Additionally, when `STATE_SERVICE_CONTAINER_IMAGE` is configured, `deploy.yaml` runs state-service smoke checks via dashboard proxy endpoints:

- `GET /api/state/catalog`
- `PUT /api/state/selection`
- `GET /api/state/selection`

These checks validate state-service availability and write/read behavior after deploy.

## State-service security mode

- State-service ingress defaults to internal-only in Terraform (`state_service_external_enabled = false`).
- When `STATE_SERVICE_SHARED_TOKEN` is set, dashboard proxy injects `X-State-Service-Token` and state-service rejects requests without a valid token.

## Private state-service image auth (GHCR)

When `STATE_SERVICE_CONTAINER_IMAGE` points to a private `ghcr.io` image, deploy jobs pass registry credentials into Terraform so Azure Container Apps can pull the image:

- `STATE_SERVICE_REGISTRY_PASSWORD` (GitHub environment secret; token with `read:packages`)
- `STATE_SERVICE_REGISTRY_USERNAME` (GitHub variable; optional, defaults to repository owner)

If these are missing for a private image, Azure Container Apps (ACA) revision provisioning may fail with `UNAUTHORIZED: authentication required`.

### Model fallback rules

- Requested models are used first.
- If `/v1/models` returns model IDs, gateway-compatible IDs are preferred.
- Azure OpenAI deployment IDs are considered as fallback candidates.
- Responses-model fallback does not overwrite a model already valid in gateway `/v1/models`.

## Production endpoint guard

In `deploy-prod`, quickcheck enforces endpoint host consistency:

- `AZURE_OPENAI_ENDPOINT` host must be `mys-prod-ai-san.cognitiveservices.azure.com`.
- Mismatch fails fast before apply/smoke test.

## Related files

- Workflow: `.github/workflows/deploy.yaml`
- Smoke test action: `.github/actions/smoke-test-gateway/action.yml`
- Secrets guidance: [SECRETS.md](SECRETS.md)
- OIDC guidance: [AZURE_OIDC_SETUP.md](AZURE_OIDC_SETUP.md)
