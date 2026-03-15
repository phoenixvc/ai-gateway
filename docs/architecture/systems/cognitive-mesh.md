# Cognitive Mesh

Cognitive Mesh architectures orchestrate multiple AI agents and tools. The SLM is the **control fabric** that decides which specialist acts, whether decomposition is needed, what context is necessary, and when to escalate.

## Architecture

```text
User Query
      │
      ▼
┌─────────────────────────────────────┐
│         SLM Control Fabric           │
│  (routing, decomposition, compression)│
└─────────────────────────────────────┘
      │
      ▼
Routing Decision
      │
      ├─→ Code Agent
      ├─→ Infra Agent
      ├─→ Security Agent
      └─→ Research Agent
            │
            ▼
      Specialist Work
            │
            ▼
      LLM Synthesis (only when needed)
```

## Strong SLM Roles in Cognitive Mesh

### 1. Router

Pick which specialist or workflow handles the request.

```json
{
  "agent": "code_agent",
  "confidence": 0.94,
  "reasoning": "User is asking about refactoring"
}
```

### 2. Task Decomposer

Break one request into bounded subtasks.

**Example:**

User: "Analyze this repo and generate a deployment plan."

SLM decomposition:

1. repository structure analysis
2. dependency inventory
3. infrastructure detection
4. deployment strategy generation

Only the final step requires LLM.

### 3. Context Compressor

Reduce token load before LLM synthesis.

```json
{
  "summary": "User wants Azure cost analysis",
  "relevant_files": ["infra/main.tf", "infra/outputs.tf"],
  "active_task": "generating cost breakdown",
  "pruned_messages": 12
}
```

### 4. Failure Classifier

Classify failures to determine retry strategy:

```json
{
  "failure_type": "tool_error",
  "retryable": true,
  "cause": "transient_network",
  "action": "retry_with_backoff"
}
```

## Practical Pattern

A good mesh uses:

1. **SLM first** — routing, decomposition
2. **Tools/specialists second** — execution
3. **LLM only for synthesis** — or when ambiguous

## Implementation

### Agent Selection

```python
async def select_agent(user_request: str) -> Agent:
    # SLM determines best agent
    classification = await slm_classify_intent(user_request)

    agent_map = {
        "code": CodeAgent,
        "infrastructure": InfraAgent,
        "security": SecurityAgent,
        "research": ResearchAgent,
    }

    return agent_map[classification.agent]
```

### Task Decomposition

```python
async def decompose_task(request: str) -> TaskPlan:
    # SLM breaks down into subtasks
    decomposition = await slm_decompose(request)

    return TaskPlan(
        subtasks=decomposition.steps,
        dependencies=decomposition.dependencies,
        llm_required_at_step=decomposition.final_step_only
    )
```

### Context Compression

```python
async def compress_context(messages: list[Message]) -> Compressed:
    summary = await slm_summarize(messages)

    return Compressed(
        summary=summary.state,
        relevant=summary.relevant_messages,
        token_estimate=summary.tokens
    )
```

## Tradeoffs

| Pros                            | Cons                                            |
| ------------------------------- | ----------------------------------------------- |
| Large token savings             | Decomposition quality can bottleneck workflow   |
| Better determinism              | Brittle routing if taxonomy is poor             |
| Easier specialist orchestration | Harder debugging if confidence handling is weak |
| Improved auditability           |                                                 |

## Key Concerns

| Concern            | Strategy                                  |
| ------------------ | ----------------------------------------- |
| Routing accuracy   | Validate against known agent capabilities |
| Task complexity    | SLM estimates; LLM confirms if wrong      |
| Agent coordination | SLM manages task queue and dependencies   |
| Failure detection  | SLM monitors logs; LLM only for recovery  |

## Agent Capabilities Matrix

| Agent    | SLM Handles                    | LLM Required For    |
| -------- | ------------------------------ | ------------------- |
| Code     | file operations, git commands  | complex refactoring |
| Infra    | terraform plans, status checks | architecture design |
| Security | vulnerability scanning         | threat analysis     |
| Research | information retrieval          | synthesis           |

## Implementation Checklist

- [ ] Define agent taxonomy with capabilities
- [ ] Implement SLM router with structured output
- [ ] Add task decomposition with bounded subtasks
- [ ] Implement context compression before LLM
- [ ] Add failure classification for retry logic
