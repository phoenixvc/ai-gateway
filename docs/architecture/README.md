# Small Language Models (SLM)

A Small Language Model (SLM) is a language model with significantly fewer parameters and lower computational requirements than large models such as GPT-class systems. While definitions vary, SLMs typically fall into the tens of millions to a few billion parameters, compared with tens or hundreds of billions in large models.

## Examples

- Phi-2
- Phi-3
- Llama 3 8B
- Gemma
- Mistral 7B

Although some of these approach the boundary between "small" and "medium," they are still commonly used where full-scale LLM infrastructure is impractical.

## Core Characteristics

| Property          | Small Language Model           | Large Language Model |
| ----------------- | ------------------------------ | -------------------- |
| Parameter count   | ~10M–10B                       | 50B–1T+              |
| Hardware          | CPU / small GPU / edge devices | multi-GPU clusters   |
| Latency           | low                            | moderate/high        |
| Memory footprint  | small                          | large                |
| Cost per request  | low                            | higher               |
| Reasoning ability | limited                        | stronger             |

## Architectural Patterns

### 1. Cascade Architecture

```
SLM
 ↓ confidence high
Return result

SLM
 ↓ confidence low
LLM escalation
```

This is widely used in AI cost optimization pipelines.

### 2. Router + Specialists

```
Router (SLM)
  ├─ Code model
  ├─ Security model
  ├─ Cost analysis model
  └─ General LLM fallback
```

SLMs act as intent classifiers.

### 3. Local-First AI

```
Device
 ├─ SLM
 ├─ embeddings
 └─ local vector store
```

Cloud models are only used when needed.

## Typical Modern AI Stack

```
                User Request
                     │
                Router (SLM)
          ┌──────────┼──────────┐
          │          │          │
     Tool call    Specialist    LLM
      (cheap)       (SLM)     (expensive)
```

This hybrid architecture is becoming the dominant design pattern in AI systems.

## Advantages

### 1. Cost Efficiency

A typical cost comparison:

| Model type | Approx cost               |
| ---------- | ------------------------- |
| SLM        | ~1–5% of large model cost |
| LLM        | baseline                  |

For large pipelines this difference becomes dominant.

### 2. Low Latency

SLMs can respond in 10–100 ms, especially when running locally.

### 3. Deployability

They can run on:

- CPUs
- edge GPUs
- phones
- embedded boards

### 4. Privacy and Data Control

Data never leaves the environment. Important for:

- healthcare
- finance
- internal enterprise tooling

## Limitations

### 1. Reduced Reasoning Ability

SLMs struggle with:

- multi-step reasoning
- long planning chains
- abstract reasoning
- ambiguous tasks

### 2. Smaller Context Windows

Often limited to 4k–32k tokens, though some newer ones extend further.

### 3. Knowledge Coverage

Because they are smaller:

- less general knowledge
- more hallucination risk without grounding

### 4. Prompt Sensitivity

They require:

- cleaner prompts
- tighter task definitions
- structured inputs

## Practical Tradeoff Summary

| Factor          | Prefer SLM | Prefer LLM |
| --------------- | ---------- | ---------- |
| cost            | ✓          |            |
| latency         | ✓          |            |
| edge deployment | ✓          |            |
| reasoning       |            | ✓          |
| creativity      |            | ✓          |
| complex tasks   |            | ✓          |
