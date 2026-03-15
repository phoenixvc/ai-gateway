# AI Gateway

AI Gateway sits between applications and multiple AI providers. The SLM acts as the **admission control and routing brain** — the fast, cheap, deterministic control layer before expensive model invocation.

## Architecture

```
Client Request
      │
      ▼
┌─────────────────────────────────────┐
│         SLM Control Layer            │
│  (intent, complexity, risk, tools)  │
└─────────────────────────────────────┘
      │
      ▼
Routing Decision
      │
      ├─→ Cache (if cacheable)
      ├─→ Tool call
      ├─→ SLM response
      ├─→ Small model
      └─→ Large model escalation
```

## SLM as Admission Control

The SLM sits **before** expensive model invocation and sometimes **after** provider response for tagging/telemetry normalization.

### Best SLM Use Cases

| Use Case                 | Description                    | Output Schema                      |
| ------------------------ | ------------------------------ | ---------------------------------- |
| Intent Classification    | Determine user intent          | `{ "intent": "code_review", ... }` |
| Complexity Scoring       | Rate request complexity        | `{ "complexity": "medium", ... }`  |
| Tool Eligibility         | Detect if tool call needed     | `{ "tool_candidate": true, ... }`  |
| Safety Prefiltering      | Prompt injection, PII, secrets | `{ "risk": "low", ... }`           |
| Cache Key Enrichment     | Generate cache keys            | `{ "cacheable": false, ... }`      |
| Telemetry Categorization | Tag for observability          | `{ "category": "analysis", ... }`  |
| Tenant Policy Gating     | Per-tenant routing rules       | `{ "tier": "premium", ... }`       |

### Why This Works

These tasks are:

- **Short-context** — SLM handles easily
- **Repetitive** — High cache hit potential
- **Structured** — Schema-bound outputs
- **Latency-sensitive** — SLM is fast

### Good SLM Output

```json
{
  "intent": "code_review",
  "complexity": "medium",
  "tool_candidate": true,
  "risk": "low",
  "cacheable": false,
  "recommended_tier": "large"
}
```

## Implementation

### Routing Logic

```python
async def gateway_admission(request: Request) -> AdmissionDecision:
    # SLM does admission control
    classification = await slm_classify(request.prompt)

    # Route based on classification
    if classification.cacheable:
        cached = await check_cache(classification.cache_key)
        if cached:
            return CachedResponse(cached)

    if classification.tool_candidate:
        return await route_to_tools(classification)

    if classification.complexity == "low":
        return await route_to_slm(classification)

    # Escalate to LLM
    return await route_to_llm(classification)
```

### Policy Check Pipeline

```python
async def security_scan(prompt: str) -> SecurityResult:
    checks = await asyncio.gather(
        slm_check_injection(prompt),
        slm_check_pii(prompt),
        slm_check_secrets(prompt)
    )

    if any(check.flagged for check in checks):
        return SecurityResult(blocked=True, reason=checks)

    return SecurityResult(allowed=True)
```

## Tradeoffs

| Pros                            | Cons                                               |
| ------------------------------- | -------------------------------------------------- |
| Major cost reduction            | Misrouting risk if classifier is weak              |
| Consistent routing              | Small models can under-detect subtle safety issues |
| Lower p95 latency               | More moving parts in gateway logic                 |
| Easier telemetry and governance |                                                    |

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

## Implementation Checklist

- [ ] Add SLM policy envelope returning intent, complexity, risk, cacheability, tier
- [ ] Implement cascade pattern for low confidence → LLM
- [ ] Add security prefiltering (injection, PII, secrets)
- [ ] Set up cost tracking per tier
- [ ] Configure latency alerts
