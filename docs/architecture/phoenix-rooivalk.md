# PhoenixRooivalk

PhoenixRooivalk is an edge AI counter-UAS (Unmanned Aerial System) system. **SLM must NOT be the primary kinetic or safety-critical decision-maker** — it sits in interpretation and operator-support layer only.

## Architecture

```
Sensors
  │
  ▼
┌─────────────────────────────────────┐
│  Rules + Signal Models + Fusion      │
│   (core detection - NOT SLM)        │
└─────────────────────────────────────┘
  │
  ▼
Threat Detection
  │
  ▼
┌─────────────────────────────────────┐
│      SLM Interpretation Layer        │
│  (summaries, reports, narratives)    │
└─────────────────────────────────────┘
  │
  ▼
Operator Console
```

## Critical Principle

> Use **rules + signal models + fusion engine** for core detection.
> Use **SLM only** for human-readable interpretation and workflow assistance.

**Never use SLM for:**

- Primary safety-critical actuation
- Final kinetic authorization
- Real-time hard control loops
- Deterministic low-level signal classification (use classical/ML models)

## Good SLM Use Cases

| Use Case               | Description                 | Output                                   |
| ---------------------- | --------------------------- | ---------------------------------------- |
| Alert Summaries        | Format alerts for operators | "Drone approaching from NW at 35m"       |
| Event Clustering       | Group similar events        | `{ "cluster": "loitering", "count": 3 }` |
| Post-Mission Narrative | Generate mission reports    | Full structured report                   |
| SOP Lookup             | Suggest procedures          | `{ "sop": "perimeter breach" }`          |
| Incident Drafting      | Draft incident reports      | Human-readable report                    |
| Telemetry Translation  | Convert raw to text         | "RF signature consistent with..."        |

## Example SLM Outputs

### Alert Summary

```json
{
  "summary": "Drone detected approaching perimeter at 35m altitude",
  "classification": "suspicious",
  "confidence": 0.74,
  "relevant_sensors": ["radar", "rf"],
  "operator_action": "monitor"
}
```

### Post-Mission Narrative

```
Mission Summary:
- Duration: 45 minutes
- Events detected: 3
- Threats: 1 (non-critical)
- Actions taken: Monitor mode

Key Event:
14:32 - Drone detected approaching perimeter from NW
Classification: Consumer quadcopter (RF signature match)
Resolution: Left area at 14:38
```

## Implementation

### Edge Processing Pipeline

```python
class EdgeProcessor:
    def __init__(self):
        self.slm = load_local_slm()  # Gemma or Phi-3

    async def process_telemetry(self, raw_stream: bytes) -> ProcessedEvent:
        # Core detection is NOT SLM - rules + signal models
        detection = self.fusion_engine.process(raw_stream)

        if detection.threat_level > THRESHOLD:
            # SLM only for human interpretation
            summary = await self.slm.summarize(detection)

        return ProcessedEvent(
            detection=detection,
            summary=summary,  # SLM output
            timestamp=datetime.utcnow()
        )
```

### Alert Formatting

```python
async def format_alert(detection: Detection) -> OperatorAlert:
    prompt = f"""Format this detection for operator:

Radar: {detection.radar_summary}
RF: {detection.rf_signature}
Flight: {detection.flight_pattern}

Output: summary, classification, recommended_action"""

    return await slm_completion(prompt)
```

### Report Generation

```python
async def generate_mission_report(events: list[Event]) -> MissionReport:
    prompt = f"""Generate post-mission report:

Events: {format_events(events)}
Duration: {mission.duration}

Output: structured report with key findings"""

    return await slm_completion(prompt)
```

## Tradeoffs

| Pros                          | Cons                                                         |
| ----------------------------- | ------------------------------------------------------------ |
| Better operator comprehension | Hallucinated interpretations dangerous if presented as facts |
| Faster report generation      | Must clearly separate inferred from sensor facts             |
| Reduced cognitive load        | Offline edge deployment constraints                          |

## Key Concerns

| Concern                   | Strategy                                     |
| ------------------------- | -------------------------------------------- |
| Safety-critical decisions | Never use SLM for actuation                  |
| Hallucination             | Clearly label SLM output as "interpretation" |
| Edge constraints          | Optimize SLM for edge (quantization)         |
| Offline operation         | Full local inference capability              |

## Hardware Options

| Device      | SLM Capability    | Notes                   |
| ----------- | ----------------- | ----------------------- |
| Jetson Nano | Phi-3 Mini (int4) | ~5ms inference          |
| Jetson Orin | Phi-3 Mini (fp16) | Real-time processing    |
| Edge CPU    | Gemma 2B          | Offline fallback        |
| Mobile SoC  | Phi-3 Mini (int4) | Phone/tablet deployment |

## Model Optimization

```python
# Quantize for edge deployment
from optimum.quanto import quantize

model = quantize(
    original_model,
    weights=quantization_type.q4,
    activations=quantization_type.q8
)
```

## Implementation Checklist

- [ ] Separate SLM from core detection pipeline
- [ ] Implement alert summarization for operators
- [ ] Add post-mission narrative generation
- [ ] Clearly label SLM output vs sensor facts
- [ ] Optimize for edge deployment
- [ ] Test offline operation
