# ADR-003 — Engineering Core as Platform Core

- Status: Accepted with boundary correction required
- Context: Domains need shared events, commands, queries, history, cache, graph, services and runtime concepts.
- Problem: Duplicated infrastructure prevents coherent Project First behavior.
- Alternatives: independent domain infrastructure; global service locator; explicit Engineering Context.
- Decision: Engineering Core provides platform contracts and per-project context.
- Consequences: consistent integration and traceability; current standard factory became over-aware of higher domains.
- Future impact: move concrete registration to the app composition root while retaining Engineering Core contracts.
