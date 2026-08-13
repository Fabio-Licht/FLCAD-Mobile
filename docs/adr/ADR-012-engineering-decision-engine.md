# ADR-012: Centralize engineering decisions in EDE

Status: Accepted

## Decision

All new cross-domain engineering choices are represented by `EngineeringDecision` and created through `DecisionApi`. Specialist engines provide evidence and candidates, but do not silently select a platform-wide action. Professional Workflow consumes EDE decisions through an adapter.

## Consequences

Decisions become reproducible, graph-aware and auditable. Human overrides and regional choices share one model. Legacy domain recommendations remain compatible evidence sources during migration. No decision implies CAD execution unless a future real executor reports it separately.
