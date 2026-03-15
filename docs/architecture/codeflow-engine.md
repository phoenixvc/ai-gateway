# CodeFlow Engine

CodeFlow Engine is a DevOps and CI/CD intelligence system. SLMs are extremely efficient for many CI tasks.

## Architecture

```
Git Push
   │
   ▼
CodeFlow Engine
   │
   ├─ SLM: commit classification
   ├─ SLM: risk analysis
   ├─ SLM: CI log analysis
   │
   ▼
CI/CD Actions
   ├─ auto approve
   ├─ run full tests
   └─ escalate review
```

## SLM Use Cases

### 1. Pull Request Classification

SLM categorizes PRs:

```json
{
  "type": "documentation",
  "risk": "low",
  "tests_required": false,
  "reviewers_needed": 1
}
```

### 2. Commit Message Analysis

SLM determines:

- semantic change type
- breaking change risk
- release notes impact

### 3. CI Failure Diagnosis

SLM reads build logs and classifies failures.

**Example output:**

```json
{
  "failure_type": "dependency_error",
  "likely_cause": "missing npm package",
  "suggested_fix": "npm install",
  "severity": "medium"
}
```

## Implementation

### PR Classification

```python
async def classify_pr(pr_diff: str, pr_description: str) -> PRClassification:
    prompt = f"""Classify this PR:

Diff: {pr_diff[:2000]}
Description: {pr_description}

Output JSON with: type, risk_level, tests_required, reviewers_needed"""

    result = await slm_completion(prompt)
    return PRClassification.parse_json(result)
```

### Commit Analysis

```python
async def analyze_commit(commit: Commit) -> CommitAnalysis:
    prompt = f"""Analyze this commit:

Message: {commit.message}
Files: {commit.changed_files}

Determine: breaking_change_risk, release_note_needed, impact_area"""

    return await slm_completion(prompt)
```

### CI Log Diagnosis

```python
async def diagnose_failure(build_log: str) -> Diagnosis:
    prompt = f"""Diagnose this CI failure:

Log (last 5000 chars):
{build_log[-5000:]}

Output: failure_type, likely_cause, suggested_fix"""

    return await slm_completion(prompt)
```

### Auto-Classification Rules

```python
# Map SLM output to actions
CLASSIFICATION_ACTIONS = {
    ("docs", "low"): {"auto_merge": True, "ci_skip": True},
    ("feat", "low"): {"auto_merge": False, "ci_full": True},
    ("fix", "medium"): {"auto_merge": False, "ci_full": True, "security_review": True},
    ("refactor", "low"): {"auto_merge": True, "ci_minimal": True},
}
```

## Key Concerns

| Concern  | Strategy                                        |
| -------- | ----------------------------------------------- |
| Speed    | SLM must complete in <2s                        |
| Accuracy | Validate against rules; escalate on uncertainty |
| Cost     | Batch processing; SLM only for classification   |
| Coverage | Handle all common CI scenarios                  |

## Classification Types

| Change Type   | SLM Output   | CI Action        |
| ------------- | ------------ | ---------------- |
| documentation | risk: low    | skip tests       |
| bugfix        | risk: medium | run tests        |
| refactor      | risk: low    | run tests        |
| security      | risk: high   | full review      |
| breaking      | risk: high   | require approval |

## Metrics

- Classification accuracy
- Auto-merge success rate
- Mean time to diagnosis
- Cost per PR processed
- False positive rate on security flags
