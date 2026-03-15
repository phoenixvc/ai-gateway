# Shared Contracts

Standardized JSON schemas used across all systems for consistent telemetry, routing, and event handling.

---

## RoutingDecision

Emitted for every routing decision in the gateway.

```json
{
  "intent": "string",
  "complexity": "low|medium|high",
  "risk_level": "low|medium|high|critical",
  "policy_status": "allow|redact|deny|review",
  "needs_tool": true,
  "recommended_tier": "slm|llm",
  "recommended_path": "direct|tool_first|mesh|escalate",
  "confidence": 0.0
}
```

| Field            | Type    | Description                                   |
| ---------------- | ------- | --------------------------------------------- |
| intent           | string  | Classified intent (e.g., "ci_failure_triage") |
| complexity       | enum    | Estimated task complexity                     |
| risk_level       | enum    | Risk assessment                               |
| policy_status    | enum    | Policy engine result                          |
| needs_tool       | boolean | Whether tool invocation is required           |
| recommended_tier | enum    | SLM or LLM recommendation                     |
| recommended_path | enum    | Execution path recommendation                 |
| confidence       | float   | 0.0-1.0 confidence score                      |

---

## ModelUsageEvent

Emitted for every model invocation for cost tracking and quality analysis.

```json
{
  "trace_id": "uuid",
  "system": "ai-gateway",
  "model_tier": "slm",
  "model_name": "phi-4-mini",
  "token_in": 320,
  "token_out": 64,
  "latency_ms": 41,
  "estimated_cost": 0.0002
}
```

| Field          | Type   | Description                  |
| -------------- | ------ | ---------------------------- |
| trace_id       | uuid   | Distributed trace identifier |
| system         | string | Originating system           |
| model_tier     | enum   | slm or llm                   |
| model_name     | string | Specific model used          |
| token_in       | int    | Input tokens                 |
| token_out      | int    | Output tokens                |
| latency_ms     | int    | Response time                |
| estimated_cost | float  | Estimated cost in USD        |

---

## ToolExecutionEvent

Emitted for every tool invocation through the Tool Broker.

```json
{
  "trace_id": "uuid",
  "tool_name": "azure_cli",
  "action": "monitor_query",
  "success": true,
  "latency_ms": 820,
  "retry_count": 1
}
```

| Field       | Type    | Description                  |
| ----------- | ------- | ---------------------------- |
| trace_id    | uuid    | Distributed trace identifier |
| tool_name   | string  | Tool identifier              |
| action      | string  | Action performed             |
| success     | boolean | Execution outcome            |
| latency_ms  | int     | Execution time               |
| retry_count | int     | Number of retries            |

---

## EdgeEscalationPacket

Compressed escalation from PhoenixRooivalk edge nodes.

```json
{
  "event_id": "uuid",
  "site_id": "string",
  "event_label": "rf_anomaly",
  "summary": "Consumer quadcopter signature near perimeter",
  "confidence": 0.77,
  "telemetry_refs": ["blob://..."],
  "requires_cloud_analysis": true
}
```

| Field                   | Type    | Description                       |
| ----------------------- | ------- | --------------------------------- |
| event_id                | uuid    | Unique event identifier           |
| site_id                 | string  | Edge site identifier              |
| event_label             | string  | Classified event type             |
| summary                 | string  | Compressed human-readable summary |
| confidence              | float   | 0.0-1.0 confidence score          |
| telemetry_refs          | array   | Blob references for raw telemetry |
| requires_cloud_analysis | boolean | Needs LLM-level analysis          |
