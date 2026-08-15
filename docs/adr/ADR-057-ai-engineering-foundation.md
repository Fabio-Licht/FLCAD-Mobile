# ADR-057 — AI Engineering Foundation

## Status

Accepted for Sprint G-012A.

## Decision

AI Engineering is a Project First, deterministic and consultative module. It
receives immutable engineering context snapshots and produces hypotheses,
auditable scores, technical evidence and recommendations. It never calls the
geometric kernel, executes a command, mutates geometry or accepts/rejects a
hypothesis on behalf of the user.

The dependency direction is one-way: Recognition → Topology → Continuity →
Surface Operations → Morph → Manufacturing → AI Engineering → Live
Reconstruction. Integrations exchange snapshots and identifiers, preventing
circular dependencies. Extend, Reduce, Fair, Boundary and Advanced Surface are
registered context providers in the official module graph.

## Contracts and flow

`AIEngineeringFactory` is passive: constructing it performs no I/O. Context is
loaded only when a caller starts a session, and files are created only by an
explicit persist request. `EngineeringIntentEngine` builds candidates from the
requested intent classes and deterministic feature vector. Every candidate has
at least one evidence record and a `ConfidenceEngine` score calculated from
explicit, configurable, normalized weights.

The advisor only projects candidates as recommendations. User decisions are
append-only, sequenced history entries; rollback selects an earlier history
prefix. Analytics use deterministic work units. Wall-clock analysis duration
may be supplied by the caller but is never measured with timers in the engine.

## Persistence and audit

All artifacts live under the active project at `CAD/AIEngineering`: Sessions,
Contexts, Hypotheses, History, Analytics, Recommendations and Audit. There is no
global repository, fallback path, parallel STL parser, worker, isolate,
generative AI or simulated geometry. The audit artifact records input scores,
weights, and the invariants `automaticDecisions=false` and
`geometryModified=false`.

## Consequences

Identical ordered input snapshots yield identical serialized sessions and
recommendations. Future statistical or generative providers must be separate
optional proposal sources and cannot bypass evidence, scoring, user decision,
Project First persistence, or the no-geometry-mutation boundary.
