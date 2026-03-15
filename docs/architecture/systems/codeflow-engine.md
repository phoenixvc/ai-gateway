# CodeFlow Engine

CodeFlow Engine is a DevOps and CI/CD intelligence system. **This is one of the most natural SLM fits** — CI/CD emits lots of repetitive semi-structured text where SLMs excel.

## Architecture

```text
Git Push / PR Event
      │
      ▼
┌─────────────────────────────────────┐
│         SLM Triage Layer             │
│  (classification, risk, pipeline)    │
└─────────────────────────────────────┘
      │
      ▼
CI/CD Decision
      │
      ├─→ Auto approve
      ├─→ Run tests (full/minimal/skip)
      ├─→ Security review
      └─→ Escalate to LLM
```

## Best SLM Use Cases

| Use Case                 | Description               | Example Output                                                |
| ------------------------ | ------------------------- | ------------------------------------------------------------- |
| PR Classification        | Categorize change type    | `{ "type": "api_contract", "risk": "high" }`                  |
| Test Selection           | Choose which tests to run | `{ "run_unit": true, "run_integration": false }`              |
| Blast Radius             | Estimate change impact    | `{ "impacted": ["schemas", "api"], "risk": "medium" }`        |
| Changelog Category       | Generate release notes    | `{ "category": "feature", "component": "gateway" }`           |
| Build Log Classification | Diagnose failures         | `{ "failure": "dependency_error", "fix": "npm install" }`     |
| Flaky Test Grouping      | Identify test patterns    | `{ "flaky_group": "network_timed_out" }`                      |
| Issue Routing            | Route to component owners | `{ "component": "infrastructure", "owner": "platform-team" }` |

## Example SLM Outputs

### PR Classification

```json
{
  "change_type": "api_contract",
  "risk": "high",
  "requires_full_ci": true,
  "security_review": false,
  "impacted_domains": ["schemas", "api"],
  "suggested_reviewers": ["platform-team"]
}
```

### Failure Diagnosis

```json
{
  "failure_type": "dependency_resolution",
  "retryable": false,
  "likely_root_cause": "missing package lock update",
  "suggested_action": "regenerate lock file and rerun"
}
```

## Why This Works

CI/CD emits lots of repetitive semi-structured text:

- Similar commit patterns
- Recurring error types
- Predictable change categories

SLMs do very well at pattern recognition on this data.

## Implementation

### PR Classification

```python
async def classify_pr(pr_diff: str, pr_description: str) -> PRClassification:
    prompt = f"""Classify this PR:

Diff (first 2000 chars): {pr_diff[:2000]}
Description: {pr_description}

Output JSON with: type, risk_level, tests_required, reviewers_needed, security_review"""

    result = await slm_completion(prompt)
    return PRClassification.parse_json(result)
```

### Test Selection

```python
async def select_tests(change_type: str, impacted_files: list[str]) -> TestPlan:
    prompt = f"""Select tests for this change:

Type: {change_type}
Files: {', '.join(impacted_files)}

Output: {{ "run_unit": bool, "run_integration": bool, "run_e2e": bool, "skip_reason": str|null }}"""

    return await slm_completion(prompt)
```

### Failure Diagnosis

```python
async def diagnose_failure(build_log: str) -> Diagnosis:
    prompt = f"""Diagnose this CI failure:

Log (last 5000 chars):
{build_log[-5000:]}

Output: failure_type, retryable, likely_root_cause, suggested_action"""

    return await slm_completion(prompt)
```

### Auto-Rules Mapping

```python
CLASSIFICATION_ACTIONS = {
    ("docs", "low"): {"auto_merge": True, "ci_skip": True},
    ("feat", "low"): {"auto_merge": False, "ci_full": True},
    ("fix", "medium"): {"auto_merge": False, "ci_full": True, "security_review": True},
    ("refactor", "low"): {"auto_merge": True, "ci_minimal": True},
    ("api_contract", "high"): {"auto_merge": False, "ci_full": True, "security_review": True},
}
```

## Tradeoffs

| Pros                                | Cons                                              |
| ----------------------------------- | ------------------------------------------------- |
| Cheaper automated repo intelligence | Incorrect risk can under-test changes             |
| Better developer feedback speed     | Failure summarization may miss subtle root causes |
| Fewer wasted full-pipeline runs     | Rules should never override hard safety gates     |

## Key Concerns

| Concern  | Strategy                                        |
| -------- | ----------------------------------------------- |
| Speed    | SLM must complete in <2s                        |
| Accuracy | Validate against rules; escalate on uncertainty |
| Cost     | Batch processing; SLM only for classification   |
| Coverage | Handle all common CI scenarios                  |

## Classification Types

| Change Type   | SLM Output   | CI Action          |
| ------------- | ------------ | ------------------ |
| documentation | risk: low    | skip tests         |
| bugfix        | risk: medium | run tests          |
| refactor      | risk: low    | run tests          |
| security      | risk: high   | full review        |
| breaking      | risk: high   | require approval   |
| api_contract  | risk: high   | full CI + security |

## Implementation Checklist

- [ ] Add PR classification with structured output
- [ ] Implement test selection hints
- [ ] Add blast radius estimation
- [ ] Implement failure diagnosis with suggested actions
- [ ] Set up changelog category generation
- [ ] Configure auto-merge rules
