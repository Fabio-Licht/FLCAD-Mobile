# ADR-061 — Professional Reconstruction Strategy AI

## Status

Accepted for Sprint G-012E.

## Decision

Reconstruction Strategy AI is a deterministic and consultative planning layer
over Engineering Features and Smart References. It creates immutable plans,
not CAD geometry. No step can execute a command, create an entity or mutate a
model. Acceptance, editing and rejection are explicit user actions recorded in
versioned session history.

## Engineering Playbook

Every part receives a persisted Playbook containing the highest-confidence
strategy, ordered steps, a technical justification and audit version. Each step
identifies its objective, Feature, primitives, references, dependencies,
prerequisites, order and justification. User edits create a new immutable step
revision and a new Playbook audit version; rollback restores the earlier
session version.

## Multi-strategy planning and manufacturing variants

The planner produces five complete alternatives covering maximum precision,
productivity, manufacturing preparation, additive manufacturing and
inspection. Together they provide machining, molding, stamping, 3D printing
and inspection variants. Each records deterministic estimated duration,
complexity, risk, confidence and justification using explicit versionable
policies rather than runtime timing.

## Dependency scheduling and explainability

`DependencyScheduler` builds a directed graph from step prerequisites. Graphs
validate endpoints and reject cycles. Engineering Reasoning explains ordering,
supporting-surface priority, main-axis selection and discarded hypotheses.
Recommendations expose evidence, Primitive/Feature graph identifiers and Smart
Reference IDs.

## Integration and persistence

Dependency direction is AI Engineering Foundation → Primitive Intelligence →
Engineering Feature Intelligence → Smart Reference System → Reconstruction
Strategy AI → Manufacturing/Live Reconstruction. Only immutable snapshots and
IDs cross module boundaries.

Project First persistence uses `CAD/ReconstructionStrategies`,
`EngineeringPlaybooks`, `StrategyGraphs`, `DependencyGraphs`,
`DifficultyAnalysis`, and `StrategyAnalytics`. There are no timers, isolates,
workers, fallbacks, STL parsers, ML, LLMs or generative AI.
