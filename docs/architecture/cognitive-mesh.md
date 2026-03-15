# Cognitive Mesh

Cognitive Mesh architectures orchestrate multiple AI agents and tools. The biggest challenge is orchestration intelligence—SLMs are ideal for the coordination layer.

## Architecture

```
User Query
    │
    ▼
SLM Router
    │
    ├─ Code Agent
    ├─ Infra Agent
    ├─ Security Agent
    └─ Research Agent
          │
          ▼
     Specialist Work
          │
          ▼
   LLM (only when required)
```

## SLM Use Cases

### 1. Agent Router

Determine which specialist agent should handle a request.

**Example agents:**

- code agent
- research agent
- infrastructure agent
- financial agent
- security agent

SLM acts as a deterministic routing layer.

### 2. Task Decomposition

SLM splits requests into tasks:

**Example:**

User request: "Analyze this repo and generate a deployment plan."

SLM decomposition:

1. repository structure analysis
2. dependency inventory
3. infrastructure detection
4. deployment strategy generation

Only the final step may require a large model.

### 3. Agent Health Monitoring

SLMs analyze:

- agent logs
- task failure messages
- retry signals

They detect issues early without invoking large models.

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

    return agent_map[classification.intent]
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

### Health Check

```python
async def check_agent_health(agent_logs: list[str]) -> HealthReport:
    # SLM analyzes logs for issues
    analysis = await slm_analyze_logs(agent_logs)

    return HealthReport(
        status=analysis.health_status,
        issues=analysis.issues,
        recommendations=analysis.recommendations
    )
```

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

## Metrics

- Routing accuracy by agent type
- Task decomposition quality (steps correct)
- Agent utilization ratio
- LLM escalation rate per agent
