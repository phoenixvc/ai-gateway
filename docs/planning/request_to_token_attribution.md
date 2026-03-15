# Request-to-Token Attribution - Implementation Plan

## Overview

- Brief summary of the feature from the PRD
- Priority: P1 - High
- Target: Enable defensible incident attribution and cost accountability

## Current State

Document the current state of the ai-gateway:

- LiteLLM Gateway running on Azure Container Apps
- JSON Logging to Log Analytics (existing)
- Prometheus Metrics at /metrics endpoint (aggregated only - no per-request)
- NO correlation IDs currently
- NO per-request token telemetry

## Architecture

Document the current architecture:

- Gateway: LiteLLM on Azure Container Apps
- State Service: FastAPI with Redis
- Dashboard: Node.js admin UI
- Infrastructure: Terraform with Azure resources
- Logging: JSON logs to Log Analytics Workspace
- Observability: Prometheus metrics endpoint

## What Can Be Done in This Repo

### Phase 1: OpenTelemetry Integration (Core Implementation)

**Implementation Approach:**

Instead of a custom callback (which requires a custom LiteLLM image), we're using LiteLLM's built-in OpenTelemetry support. This provides structured traces with token telemetry out of the box.

**Changes Made:**

- Added `otel` to LiteLLM `success_callback` and `failure_callback` in `infra/modules/aigateway_aca/main.tf`
- Added OTEL environment variables:
  - `OTEL_SERVICE_NAME` - service name for traces
  - `OTEL_TRACER_NAME` - tracer name
  - `OTEL_EXPORTER_OTLP_ENDPOINT` - OTLP collector endpoint
  - `OTEL_EXPORTER_OTLP_PROTOCOL` - protocol (http/json)
- Added new variables in `infra/modules/aigateway_aca/variables.tf`:
  - `otel_exporter_endpoint` - OTLP collector URL
  - `otel_service_name` - custom service name

> **Note:** Phase 1 requires an OTLP collector endpoint to be configured. This can be a dedicated collector app, or you can send directly to a backend that supports OTLP (e.g., Application Insights, Grafana Tempo).

**How It Works:**

LiteLLM's OTEL callback automatically emits spans with:

- Model name, provider, deployment
- Token usage (prompt_tokens, completion_tokens, total_tokens)
- Duration
- Request/response metadata

**Files Modified:**

- `infra/modules/aigateway_aca/main.tf` - Added OTEL callback and env vars
- `infra/modules/aigateway_aca/variables.tf` - Added OTEL configuration variables

### Phase 2: Correlation ID Propagation

**Status: ✅ Done**

Correlation IDs flow through the system in two ways:

**Method A: Via Request Metadata (Implemented)**
Pass correlation IDs in the request body `metadata` field:

```json
{
  "model": "gpt-5.3-codex",
  "messages": [{ "role": "user", "content": "Hello" }],
  "metadata": {
    "request_id": "req_123",
    "session_id": "sess_456",
    "workflow": "manual_orchestration",
    "stage": "writer",
    "endpoint": "/api/manual-orchestration/sessions/start",
    "user_id": "user_abc" // Consider hashing/pseudonymizing for privacy
  }
}
```

> **Note:** `user_id` / `actor_id` can become PII. Consider hashing or using pseudonymous identifiers.

LiteLLM automatically passes `metadata` through to OTEL spans, making these fields available in traces.

**Method B: Via HTTP Headers (Future Enhancement)**
For clients that can only send headers, a future enhancement would add middleware to extract:

- `x-request-id`
- `x-session-id`
- `x-correlation-id`
- `x-workflow-name`
- `x-stage-name`
- `x-user-id`

This requires a custom LiteLLM wrapper or sidecar (not yet implemented).

### Phase 3: Per-Request Rollup

**Status: Not Started**

Provide request-completion rollup totals (total_tokens, llm_calls) by aggregating token counts per request_id.

**Recommendation: Option C (Downstream Aggregation)**

Start with downstream aggregation in pvc-costops-analytics - the cheapest and fastest approach. Roll up tokens by request_id/operation_id from OTEL spans without changing the gateway.

**When to consider alternatives:**

- **Option B (Collector aggregation)**: Only if you need near-real-time rollups emitted as first-class events/metrics
- **Option A (Custom LiteLLM image)**: Only if LiteLLM's built-in OTEL data is incomplete or you need strict "request complete" semantics that can't be reliably inferred downstream

## What We Need from Other Repos

### 1. cognitive-mesh (Upstream Caller)

**Required:** Pass correlation metadata in request body when calling gateway. There are two methods:

**Method A: Via Request Metadata (Recommended)**
Pass correlation IDs in the request body `metadata` field:

```json
{
  "model": "gpt-5.3-codex",
  "messages": [{ "role": "user", "content": "Hello" }],
  "metadata": {
    "request_id": "req_123",
    "session_id": "sess_456",
    "workflow": "manual_orchestration",
    "stage": "writer",
    "endpoint": "/api/manual-orchestration/sessions/start",
    "user_id": "user_abc"
  }
}
```

**Method B: Via HTTP Headers**

- x-request-id
- x-session-id
- x-correlation-id
- x-workflow-name
- x-stage-name
- x-user-id

_Note: Method B requires additional LiteLLM configuration or middleware._

### 2. pvc-costops-analytics (Downstream Analytics)

**Required:** KQL queries and dashboards to:

- Join requests table to token events by operation_Id/request_id
- Aggregate rollups by endpoint, workflow, stage, model, deployment

## Implementation Options

| Option                       | Pros              | Cons                          |
| ---------------------------- | ----------------- | ----------------------------- |
| A. Custom LiteLLM Image      | Full control      | Build/deploy overhead         |
| B. OpenTelemetry + Collector | Industry standard | Need OTEL collector           |
| C. Log Analytics Query       | No code changes   | No guarantee of 100% coverage |
| D. Sidecar Container         | Decoupled         | Additional complexity         |

**Selected:** Option B (OpenTelemetry) - Implemented in Phase 1

## Required Event Shape

```
{
  "timestamp": "2026-03-01T12:34:56Z",
  "request_id": "req_123",
  "session_id": "sess_456",
  "endpoint": "/api/manual-orchestration/sessions/start",
  "workflow": "manual_orchestration",
  "stage": "writer",
  "provider": "anthropic",
  "model": "claude-sonnet-4-5",
  "deployment": "route-a",
  "prompt_tokens": 4200,
  "completion_tokens": 2100,
  "total_tokens": 6300,
  "duration_ms": 18750
}
```

## Required Correlation Fields

- request_id
- session_id
- operation_id (App Insights)
- correlation_id (cross-service)
- endpoint_name
- workflow_name
- stage_name
- provider
- model_name
- deployment_name
- user_id / actor_id

## Acceptance Criteria

| Criterion                                    | Status    | Notes                                                   |
| -------------------------------------------- | --------- | ------------------------------------------------------- |
| 100% of LLM calls emit token telemetry       | ✅ Done   | Via OTEL callback                                       |
| 100% include workflow + stage                | 🔜 Ready  | Requires cognitive-mesh to pass metadata to gateway     |
| Support KQL joins by operation_Id/request_id | 🔜 Ready  | Requires pvc-costops-analytics to implement KQL queries |
| Request-completion rollup totals             | 🔜 Future | Requires Phase 3 (downstream aggregation)               |

## Dependencies

- cognitive-mesh: Pass correlation metadata in request body
- pvc-costops-analytics: Must create KQL queries for new event shape
- infra: Application Insights resource + APPLICATIONINSIGHTS_CONNECTION_STRING wiring added; trace export requires custom LiteLLM image (with azure-monitor-opentelemetry) or explicit OTEL_EXPORTER_OTLP_ENDPOINT configuration (currently empty by default)

## Action Items

### Completed

1. ✅ ai-gateway: Add OTEL callback for token telemetry (Phase 1)
2. ✅ ai-gateway: Document correlation ID requirements (Phase 2)
3. ✅ ai-gateway: Add Application Insights connection string wiring (Phase 1b - trace export requires custom image or OTLP collector)

### Pending

4. cognitive-mesh: Pass correlation metadata in request body
5. pvc-costops-analytics: Create KQL queries for OTEL span joins
6. pvc-costops-analytics: Implement request rollup aggregation (Phase 3)

---

## Infrastructure Decisions (Shared-Infra Adoption)

| Decision              | Value              | Rationale                                                                                        |
| --------------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| Redis/Storage needed? | No                 | OTEL sends traces directly to collector. Add Redis only if caching is needed for cost reduction. |
| Isolation level       | Shared-per-env     | Fine for initial deployment. Add dedicated resources only when there's contention.               |
| Public hostname       | Direct ACA ingress | Simpler, lower cost. Add Front Door later for WAF/custom domain.                                 |
| Environment naming    | `staging`          | Aligns with Mystira shared-infra conventions. Migrate `uat` later if needed.                     |

### Terraform Integration Notes

**Recommendation:** ai-gateway keeps owning its Terraform in its repo. Mystira workspace treats ai-gateway as an external product that consumes shared-infra via an explicit "shared resource contract".

1. **Module location**: ai-gateway owns its Terraform in this repo
2. **Shared resources to consume**:
   - Log Analytics workspace from shared outputs
   - Key Vault for secrets (use managed identity to read)
   - Optional: Redis if caching becomes necessary
3. **Naming alignment**: Use `staging` instead of `uat` for environment naming
4. **Secrets**: Write to Key Vault only; never output from Terraform
