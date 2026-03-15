# AI Gateway

AI Gateway sits between applications and multiple AI providers. Its main responsibilities include request routing, guardrails, caching, cost control, model selection, and telemetry tagging.

## Architecture

```
Client
   │
   ▼
AI Gateway
   │
   ├─ SLM: request classification
   ├─ SLM: security scan
   ├─ SLM: cost prediction
   │
   ▼
Routing Decision
   ├─ Small model
   ├─ Tool call
   └─ Large model escalation
```

## SLM Use Cases

### 1. Request Classification

Determine the intent of a prompt before routing.

**Example tasks:**

- code generation
- analysis
- summarization
- conversational
- tool execution

**SLM outputs structured routing signals:**

```json
{
  "intent": "code_generation",
  "complexity": "medium",
  "security_risk": "low",
  "suggested_model": "gpt-large"
}
```

This prevents sending every request to expensive models.

### 2. Prompt Sanitization / Policy Checks

SLM performs quick checks:

- prompt injection
- policy violations
- secrets exposure
- PII detection

This happens before any expensive inference.

### 3. Cost-aware Model Routing

SLM predicts complexity:

- low complexity → small model
- medium → mid-tier
- high → large reasoning model

## Implementation

### Routing Logic

```python
async def route_request(request: str) -> RoutingDecision:
    # Use SLM for classification
    classification = await slm_classify(request)

    if classification.confidence > 0.8:
        return await route_by_intent(classification.intent)
    else:
        return await escalate_to_llm(request)
```

### Policy Check Pipeline

```python
async def security_scan(prompt: str) -> SecurityResult:
    checks = await asyncio.gather(
        slm_check_injection(prompt),
        slm_check_pii(prompt),
        slm_check_secrets(prompt)
    )

    if any(checks.flagged for checks in checks):
        return SecurityResult(blocked=True, reason=checks)

    return SecurityResult(allowed=True)
```

## Key Concerns

| Concern  | Strategy                                     |
| -------- | -------------------------------------------- |
| Latency  | SLM runs inline; must respond in <50ms       |
| Accuracy | Cascade: low confidence → LLM verification   |
| Cost     | Route 80%+ to SLMs; LLM only for escalation  |
| Security | SLM policy check before any model invocation |

## SLM Model Selection

Recommended models for gateway classification:

- Phi-3 Mini (3.8B) - fast, accurate
- Llama 3 8B - good general classification
- Gemma 2B - minimal latency

## Metrics

Track per routing decision:

- SLM vs LLM routing ratio
- Average latency by route type
- Escalation rate (SLM → LLM)
- Cost per 1K requests
