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

### Phase 1: LiteLLM Custom Callback (Core Implementation)

**Files to modify:**

- `infra/modules/aigateway_aca/main.tf` - Add custom callback config
- Create new custom callback module

**Approach:** Use LiteLLM's CustomLogger class or success_callback to emit structured token telemetry

**Challenge:** LiteLLM runs as a container image - need to either:

1. Build a custom image with callback baked in
2. Use environment variables + config-based callback
3. Add a sidecar container

### Phase 2: Correlation ID Propagation

- Extract x-request-id, x-correlation-id headers from incoming requests
- Pass them through to LiteLLM via metadata param
- Include: endpoint_name, workflow_name, stage_name from request path

### Phase 3: Per-Request Rollup

- Track tokens per request_id in memory or Redis
- Emit summary event when request completes

## What We Need from Other Repos

### 1. cognitive-mesh (Upstream Caller)

Required: Must pass correlation headers when calling gateway:

- x-request-id
- x-session-id
- x-correlation-id
- x-workflow-name
- x-stage-name
- x-user-id

### 2. pvc-costops-analytics (Downstream Analytics)

Required: KQL queries and dashboards to:

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
