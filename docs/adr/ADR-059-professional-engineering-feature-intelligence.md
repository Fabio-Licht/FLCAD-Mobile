# ADR-059 — Professional Engineering Feature Intelligence

## Status

Accepted for Sprint G-012C.

## Decision

Engineering Feature Intelligence is a deterministic, explainable and strictly
consultative consumer of Primitive Intelligence snapshots. It correlates
primitives, topology context, axes, symmetries and patterns into feature
hypotheses. It never parses STL, calls the CAD kernel, creates entities,
executes reconstruction steps or modifies CAD geometry.

## Feature Graph and Confidence Tree

Each hypothesis owns an acyclic directed subgraph. Nodes reference official
primitive, boundary, patch, axis, point, symmetry and pattern IDs; edges carry
typed and scored relationships. Graph construction rejects unknown endpoints
and cycles.

The persisted Confidence Tree has a root overall confidence and seven auditable
branches: geometric, topology, functional, manufacturing, symmetry, context
and history. Scores derive only from recognition confidence or explicitly
supplied snapshot measurements. Configurable normalized weights calculate the
root value.

## Library, canonical features and explainability

The library enumerates holes, bosses, pockets, flanges, bearing seats,
housings, shafts, ribs, slots, keyways, draft/revolution/extrusion/loft/blend
regions, fillets, chamfers, mold/stamping/electrode candidates, machining and
datum features. Rules produce functional categories and manufacturing context.

Every recommendation records why it exists, evidence, source primitives,
relationships, scores, discarded alternatives, a canonical suggestion with
measured deviation, and a reconstruction strategy. Canonical suggestions and
strategy steps explicitly remain unapplied.

## Engineering DNA

The deterministic DNA summarizes predominant features, geometric and
topological relationships, symmetries, probable manufacturing and
reconstruction strategies, and geometric/functional complexity. It is a
reusable technical profile, not a learned embedding or similarity decision.

## Integration and persistence

Dependency direction is Recognition → Primitive Intelligence → AI Engineering
Foundation → Engineering Feature Intelligence → Manufacturing/Surface
Operations/Live Reconstruction. Integrations exchange immutable snapshots and
IDs to prevent cycles.

Explicit Project First persistence uses `CAD/EngineeringFeatures`,
`FeatureGraphs`, `FeatureTrees`, `FeatureRanking`, `FeatureAnalytics`,
`FeatureStrategies`, and `EngineeringDNA`. There are no timers, isolates,
workers, fallbacks, ML, LLMs, generative AI or automatic decisions.
