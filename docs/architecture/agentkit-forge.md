# AgentKit Forge

AgentKit Forge builds AI agents and orchestration workflows. SLMs help build scalable multi-agent systems.

## Architecture

```
Agent Task
   │
   ▼
SLM Tool Selector
   │
   ├─ GitHub API
   ├─ Azure CLI
   ├─ Terraform
   └─ Documentation Search
```

## SLM Use Cases

### 1. Tool Selection

Agent decides which tool to invoke.

**Example tools:**

- GitHub API
- Azure CLI
- Terraform
- Kusto queries
- File system operations

**SLM output:**

```json
{
  "tool": "azure_cli",
  "command": "az monitor metrics list",
  "args": {
    "resource": "/subscriptions/.../appinsights/...",
    "metric": "requests"
  },
  "confidence": 0.92
}
```

### 2. Context Compression

Agents accumulate long conversation histories.

SLM compresses them:

```json
{
  "previous_state_summary": "User requested Azure cost analysis",
  "relevant_files": ["infra/main.tf", "infra/outputs.tf"],
  "active_task": "generating cost breakdown"
}
```

### 3. Token Budget Control

SLM predicts which context segments are needed before invoking a large model.

```python
# Before calling expensive LLM
context_plan = await slm_plan_context(
    task="analyze deployment",
    available_context=["git_diff", "terraform_plan", "logs", "metrics"]
)

# Returns:
{
    "required_context": ["terraform_plan"],
    "optional_context": ["logs"],
    "estimated_tokens": 8000,
    "can_fit_in_window": true
}
```

## Implementation

### Tool Selection

```python
async def select_tool(task: str, available_tools: list[Tool]) -> ToolInvocation:
    prompt = f"""Select the best tool for this task.

Task: {task}

Available tools:
{format_tools(available_tools)}

Output: tool_name, args, confidence"""

    result = await slm_completion(prompt)
    return ToolInvocation(
        tool=result.tool,
        args=result.args,
        confidence=result.confidence
    )
```

### Context Planning

```python
async def plan_context(task: str, context_options: list[Context]) -> ContextPlan:
    prompt = f"""Plan which context to use for this task.

Task: {task}

Available context:
{format_context(context_options)}

Output: required_context, optional_context, estimated_tokens"""

    return await slm_completion(prompt)
```

### Multi-Step Reasoning

```python
async def execute_agent_task(task: str) -> AgentResult:
    # Step 1: Decompose
    plan = await slm_decompose(task)

    # Step 2: Execute each step with tool selection
    for step in plan.steps:
        tool = await select_tool(step.description, available_tools)
        result = await execute_tool(tool)

        # Step 3: Check if escalation needed
        if result.complexity == "high":
            llm_result = await llm_complete(step, context)
            result = llm_result

    return aggregate_results(plan.steps)
```

## Key Concerns

| Concern       | Strategy                               |
| ------------- | -------------------------------------- |
| Tool accuracy | Validate tool exists before invocation |
| Context bloat | SLM filters context before LLM         |
| Cost          | Route 70%+ through SLM tool selection  |
| Reliability   | Fallback to LLM on low confidence      |

## Tool Categories

| Category     | SLM Handles        | LLM Handles        |
| ------------ | ------------------ | ------------------ |
| CLI commands | selection + args   | complex pipelines  |
| API calls    | endpoint selection | response parsing   |
| File ops     | path determination | content generation |
| Queries      | query construction | result synthesis   |

## Metrics

- Tool selection accuracy
- Context compression ratio
- LLM call reduction rate
- Average task latency
- Cost per agent task
