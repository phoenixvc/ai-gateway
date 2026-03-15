# Recommended Implementation Order

For the stack, the highest ROI sequence is:

## Phase 1: Gateway Foundation

- AI Gateway intent classifier
- AI Gateway policy scan
- Route-to-tier decision
- Semantic cache admission

**Value**: Highest immediate cost-leverage

## Phase 2: CI Intelligence

- CodeFlow Engine PR risk classifier
- CodeFlow Engine CI failure bucketing
- CodeFlow Engine release-note summarizer

**Value**: Fastest operational value

## Phase 3: Agent Runtime

- AgentKit Forge tool selector
- AgentKit Forge parameter extractor
- AgentKit Forge context compressor

**Value**: Lower token burn, faster tool loops

## Phase 4: Orchestration

- Cognitive Mesh specialist router
- Cognitive Mesh decomposition engine
- Cognitive Mesh state manager

**Value**: Strong leverage once taxonomy stabilizes

## Phase 5: Edge

- PhoenixRooivalk edge event summarizer
- PhoenixRooivalk operator alert composer
- PhoenixRooivalk escalation filter

**Value**: Keep isolated from critical control

## Summary

| Phase | System          | Priority |
| ----- | --------------- | -------- |
| 1     | AI Gateway      | Highest  |
| 2     | CodeFlow        | High     |
| 3     | AgentKit Forge  | Medium   |
| 4     | Cognitive Mesh  | Medium   |
| 5     | PhoenixRooivalk | Lower    |

That order gives fastest operational value with lowest implementation risk.
