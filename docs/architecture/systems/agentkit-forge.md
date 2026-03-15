# AgentKit Forge

AgentKit Forge builds AI agents and orchestration workflows. SLMs help when agents have **many tools** and **large working memory**.

## Architecture

```text
Agent Task
      │
      ▼
┌─────────────────────────────────────┐
│      SLM Execution Governor          │
│  (tool selection, memory, budget)   │
└─────────────────────────────────────┘
      │
      ▼
Tool Selection
      │
      ├─→ GitHub API
      ├─→ Azure CLI
      ├─→ Terraform
      ├─→ Documentation Search
      └─→ LLM Synthesis
```

## Most Practical SLM Jobs

### 1. Tool Selector

Map user or system request to the right tool.

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

### 2. Relevance Filter

Only send necessary state to expensive models.

```json
{
  "relevant_context": ["terraform_plan", "error_logs"],
  "pruned_context": ["old_successful_deploys", "unrelated_metrics"],
  "estimated_tokens": 3500
}
```

### 3. Budget Governor

Estimate likely token spend and whether tool-first is sufficient.

```json
{
  "estimated_tokens": 8000,
  "can_fit_in_window": true,
  "should_use_tool_first": true,
  "budget_tier": "medium"
}
```

### 4. Execution Classifier

Distinguish how to handle the request.

```json
{
  "action": "use_tool",
  "tool_name": "github_api",
  "escalate_to_llm": false,
  "reason": "simple data retrieval"
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

### Budget Governor

```python
async def govern_budget(task: str) -> BudgetDecision:
    prompt = f"""Estimate token budget for this task.

Task: {task}

Consider: context size, expected output, complexity"""

    estimate = await slm_completion(prompt)

    return BudgetDecision(
        estimated_tokens=estimate.tokens,
        can_fit=estimate.can_fit,
        should_escalate=estimate.should_escalate
    )
```

### Multi-Step Execution

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

## Tradeoffs

| Pros                                | Cons                                           |
| ----------------------------------- | ---------------------------------------------- |
| Keeps agent execution lean          | Weak tool selection harms trust                |
| Lowers token burn dramatically      | Compressed memory can omit critical edge cases |
| Improves tool invocation discipline | Too much reliance can make agents look shallow |

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

## Implementation Checklist

- [ ] Implement tool selection with confidence scores
- [ ] Add relevance filtering for context
- [ ] Implement budget governor with token estimation
- [ ] Add execution classification (direct/tool/LLM)
- [ ] Set up fallback to LLM on low confidence
