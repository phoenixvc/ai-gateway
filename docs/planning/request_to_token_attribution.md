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

- Extract x-request-id, x-correlation-id headers from incoming requests
- Pass them through to LiteLLM via metadata param
- Include: endpoint_name, workflow_name, stage_name from request path

### Phase 3: Per-Request Rollup

- Track tokens per request_id in memory or Redis
- Emit summary event when request completes

## What We Need from Other Repos

### 1. cognitive-mesh (Upstream Caller)

**Required:** Must pass correlation headers when calling gateway. There are two methods:

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

**Recommended:** Option A (Custom LiteLLM Image) for Phase 1

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

- 100% of LLM calls emit token telemetry with request_id + operation_id
- 100% include workflow + stage
- Provide request-completion rollup totals (total_tokens, llm_calls)
- Support KQL joins requests↔token events by operation_Id/request_id

## Dependencies

- cognitive-mesh: Must pass correlation headers to gateway
- pvc-costops-analytics: Must create KQL queries for new event shape
- infra: May need custom LiteLLM container image or OTEL collector

## Action Items

1. ai-gateway: Build custom LiteLLM image with token telemetry callback
2. cognitive-mesh: Ensure correlation headers are passed to gateway
3. pvc-costops-analytics: Prepare KQL queries for new event shape
