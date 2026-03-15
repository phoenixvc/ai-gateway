# SLM Implementation Guide

## When to Use an SLM

SLMs are appropriate when:

- the task is structured
- the domain is narrow
- latency matters
- cost must be minimized
- inference must run locally

### Typical Examples

- CI/CD pipelines
- log classification
- code lint summarization
- telemetry tagging
- router agents
- RAG query classification

## When to Use a Large Model

Use a full LLM when:

- deep reasoning is required
- complex architecture planning
- research tasks
- multi-step problem solving
- creative generation
- ambiguous user requests

## Typical Use Cases

### 1. Edge and Embedded AI

SLMs are commonly used on-device.

Examples:

- mobile assistants
- IoT systems
- robotics
- drones
- offline copilots

Advantages:

- no cloud latency
- privacy (data never leaves device)
- deterministic cost

This aligns with architectures where inference must run on Jetson, mobile chips, or CPUs.

### 2. Specialized Task Models

SLMs perform well when the task domain is narrow.

Examples:

- classification
- log analysis
- document tagging
- code lint explanation
- schema validation
- chatbot for a specific knowledge base

In many cases an SLM + RAG outperforms a large model with no context.

### 3. Agent Systems and Routing

SLMs are often used as cheap first-pass models.

Typical pattern:

```
User request
     ↓
Router (SLM)
     ↓
Decision
 ├─ handle locally
 ├─ call tool
 └─ escalate to large model
```

Benefits:

- large model usage drops significantly
- lower operational cost
- deterministic routing

### 4. High-Throughput Batch Processing

SLMs are useful for:

- codebase analysis
- repository indexing
- log classification
- telemetry tagging
- document chunk summarization

When processing millions of documents, the cost difference is substantial.

## Implementation Patterns

### Router Pattern Implementation

```python
async def route_request(request: str) -> Response:
    # Use SLM for classification/routing
    intent = await slm_classify(request)

    if intent == "simple":
        return await handle_locally(request)
    elif intent == "tool":
        return await call_tool(request)
    else:
        # Escalate to full LLM
        return await llm_complete(request)
```

### Cascade Pattern Implementation

```python
async def cascade(request: str) -> Response:
    # First try SLM
    result = await slm_complete(request)

    # Check confidence
    if result.confidence > 0.85:
        return result

    # Escalate to LLM for low confidence
    return await llm_complete(request)
```

### Local-First Pattern

```
Device
 ├─ SLM (local inference)
 ├─ embeddings (local compute)
 └─ local vector store (SQLite/Chroma)
```

Cloud models only used when local SLM cannot handle the request.

## Cost Optimization Example

For a system processing 1M requests/day:

| Model      | Cost/request | Daily cost | Monthly cost |
| ---------- | ------------ | ---------- | ------------ |
| SLM (7B)   | $0.001       | $1,000     | $30,000      |
| LLM (175B) | $0.05        | $50,000    | $1,500,000   |

**Potential savings: 98%**
