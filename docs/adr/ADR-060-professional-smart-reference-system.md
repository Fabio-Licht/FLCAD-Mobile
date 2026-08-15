# ADR-060 — Professional Smart Reference System

## Status

Accepted for Sprint G-012D.

## Decision

Smart Reference System is a deterministic, explainable and consultative
downstream consumer of Engineering Feature Intelligence. It proposes planes,
axes, points, datum references and coordinate systems; it never creates those
entities, executes alignment, calls the CAD kernel or mutates geometry.

## Canonical references and ranking

`ReferenceCandidateBuilder` traces every proposal to Feature and Primitive IDs,
topological relationships and immutable evidence. `CanonicalReferenceSolver`
projects the measured reference onto a named canonical candidate and retains
angular error, confidence, justification and reasons without applying it.

Ranking has eight independently auditable branches—geometric, topology,
manufacturing, functional, symmetry, feature, context and history—and a
normalized weighted overall confidence. Weights are configurable and ties are
resolved by stable candidate ID.

## Dependency graph, datums and coordinate systems

The persistent dependency graph validates endpoints and rejects cycles. Datum
Intelligence labels the three highest ranked proposals A, B and C with explicit
justification. Coordinate System Intelligence proposes origin, orientations,
system and alignment order from ranked candidates. These remain proposals.

`AlignmentStrategyGenerator` emits three alternative ordered strategies. Each
strategy records confidence, evidence and `applied=false`. Explainable Reference
AI reports why, primitives, Features, topology, evidence, scores and discarded
alternatives for every recommendation.

## Integration and persistence

Dependency direction is AI Engineering Foundation/Recognition/Topology/
Continuity → Primitive Intelligence → Engineering Feature Intelligence → Smart
Reference System → Surface Operations/Manufacturing/Live Reconstruction. Only
snapshots and IDs cross module boundaries.

Explicit Project First persistence uses `CAD/SmartReferences`,
`ReferenceGraphs`, `ReferenceStrategies`, `AlignmentStrategies`,
`DatumSuggestions`, and `CoordinateSystems`. There are no timers, isolates,
workers, fallbacks, parallel STL parsing, ML, LLMs, generative AI or automatic
decisions.
