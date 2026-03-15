# Shared Contracts

Status: Accepted

## Routing Decision

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

## Model Usage Event

```json
{
  "trace_id": "uuid",
  "system": "ai-gateway",
  "model_tier": "slm",
  "model_name": "model-id",
  "token_in": 320,
  "token_out": 64,
  "latency_ms": 41,
  "estimated_cost": 0.0002
}
```

## Tool Execution Event

```json
{
  "trace_id": "uuid",
  "tool_name": "azure_cli",
  "action": "query_metrics",
  "success": true,
  "latency_ms": 820
}
```

## Edge Escalation Packet

```json
{
  "event_id": "uuid",
  "site_id": "string",
  "event_label": "rf_anomaly",
  "summary": "Drone signature detected near perimeter",
  "confidence": 0.78
}
```
