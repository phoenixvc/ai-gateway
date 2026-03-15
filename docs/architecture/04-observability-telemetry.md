# Observability and Telemetry

Status: Accepted

## Context

Cross-system observability is required for:

- cost visibility
- routing quality measurement
- policy enforcement evidence
- debugging and operational monitoring

## Telemetry Architecture

```mermaid
flowchart TB
    subgraph Producers
        P1[AI Gateway]
        P2[Cognitive Mesh]
        P3[AgentKit Forge]
        P4[CodeFlow Engine]
        P5[Rooivalk Edge]
    end

    subgraph Signals
        S1[Request Logs]
        S2[Routing Decisions]
        S3[Policy Events]
        S4[Tool Calls]
        S5[Model Usage]
        S6[Edge Events]
    end

    subgraph Ingest
        I1[OpenTelemetry]
        I2[Application Insights]
        I3[Blob Export]
        I4[Prometheus]
    end

    subgraph Analytics
        A1[Azure Data Explorer]
        A2[Cost Aggregates]
        A3[Quality Metrics]
    end

    subgraph Visualization
        V1[Grafana]
        V2[Alerts]
    end

    P1 --> S1
    P1 --> S2
    P1 --> S5
    P2 --> S2
    P3 --> S4
    P4 --> S1
    P5 --> S6

    S1 --> I1
    S2 --> I1
    S4 --> I1
    S5 --> I2
    S6 --> I3
    S5 --> I4

    I1 --> A1
    I2 --> A1
    I3 --> A1
    I4 --> V1

    A1 --> V1
    V1 --> V2
```

### Telemetry Sinks

LiteLLM enables Prometheus metrics via `success_callback` and `failure_callback` containing "prometheus". The Prometheus exporter exposes a `/metrics` endpoint that scrapes application metrics. See `infra/modules/aigateway_aca/main.tf:95-113` for the container configuration.

The primary telemetry sinks are:

- **OpenTelemetry**: Traces and spans
- **Application Insights**: Azure Monitor implementation using `APPLICATIONINSIGHTS_CONNECTION_STRING` env var for OTEL exporter
- **Blob Export**: Raw event storage
- **Prometheus**: Application metrics via `/metrics` endpoint

## Retention Policies

Application Insights retention defaults:

- **Production**: 90 days
- **Non-production (dev/staging)**: 30 days

These are environment-specific settings configured in the Application Insights resource. Operators can adjust retention in the Azure Portal under Application Insights resource settings.

Include retention expectations in operational runbooks to align cost and data availability expectations.

## Key Metrics

### Gateway

- routing decision distribution
- SLM vs LLM usage ratio
- cache hit rate

### CodeFlow

- PR classification accuracy
- CI triage distribution

### AgentKit

- tool selection success rate

### Rooivalk

- alert compression ratio
- edge escalation frequency
