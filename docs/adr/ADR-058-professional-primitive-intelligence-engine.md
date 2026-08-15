# ADR-058 — Professional Primitive Intelligence Engine

## Status

Accepted for Sprint G-012B.

## Decision

Primitive Intelligence is a deterministic, consultative downstream consumer
of official Recognition snapshots. It does not parse STL, inspect native mesh
data, call the CAD kernel, execute commands, or create planes, axes, references
or geometry. Its immutable output consists of ranked engineering hypotheses,
technical evidence, alignment suggestions, axis/symmetry/pattern hypotheses and
manufacturing-oriented advice.

## Classification and evidence

Each supported primitive has an explicit evidence schema. Classification uses
versionable `PrimitiveClassificationPolicy` thresholds. The policy covers
plane support/reference/symmetry, cylinder hole/main-axis/revolution, cone
draft/seat, sphere joint/reference and torus functional-radius cases. Missing
measurements are represented explicitly; they are never fabricated from
synthetic geometry.

## Alignment and ranking

Alignment normalizes the Recognition orientation and calculates absolute
angular deviation to X, Y and Z. A plane nearest Z therefore receives the
consultative wording “parallel to XY plane”; the STL is never assumed or
transformed. The same projection applies to axes for cylinders, cones and tori,
and to center direction for spheres.

Ranking uses five auditable components: confidence, importance, manufacturing,
alignment and reconstruction relevance. Only Recognition confidence and
explicit snapshot scores are used. Weights are configurable and normalized;
ties are resolved by stable hypothesis ID.

## Integration and persistence

Dependency direction is Recognition/Topology/Continuity → AI Foundation →
Primitive Intelligence → Surface Operations/Manufacturing/Live Reconstruction.
Only snapshots and IDs cross boundaries, avoiding circular dependencies.

Explicit persistence writes beneath the active project only:
`CAD/PrimitiveIntelligence`, `PrimitiveEvidence`, `PrimitiveRanking`,
`PrimitiveAnalytics`, and `PrimitiveSuggestions`. Construction and analysis are
passive with respect to disk. User acceptance/rejection is sequenced and can be
rolled back to a prior prefix.

There are no timers, isolates, workers, fallbacks, machine learning, LLMs,
generative AI or automatic decisions. Every recommendation retains its source
evidence and explicitly records that commands/entities/geometry were not
executed, created or modified.
