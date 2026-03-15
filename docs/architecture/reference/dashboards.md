# Recommended Dashboards

Grafana/ADX dashboard recommendations for operational visibility.

---

## Dashboard Pack

Split Grafana/ADX dashboards into these boards:

| Dashboard            | Metrics                                                                               |
| -------------------- | ------------------------------------------------------------------------------------- |
| **Executive / Cost** | Total requests, SLM vs LLM ratio, cost by route, cost per outcome, escalation rate    |
| **Reliability**      | Error rate, tool failure rate, retry hotspots, provider latency, queue backlog        |
| **Governance**       | Policy blocks, redaction counts, provider data-boundary usage, audit completeness     |
| **CodeFlow**         | PR risk distribution, CI triage buckets, contract-break suspects, feedback usefulness |
| **Rooivalk**         | Detections vs alerts, local vs escalated, site alert volume, edge latency             |
