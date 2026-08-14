# ADR-029 — Feature Modeling Platform

## Status

Accepted.

## Decision

Feature Modeling is a platform domain under `core/feature_modeling`. A feature in G-007A is a persistent parametric definition, timeline entry, dependency node, and future execution contract—not geometry. All twelve feature families are unsupported contracts until later sprints provide real GeometryKernelAPI executors.

The default executor returns explicit `unsupported` or `kernelUnavailable` results with no outputs. It never fabricates shape handles. Rebuild validates, orders, propagates dirty state, records failure, and provides rollback without creating solids.

Bootstrap registers factories and passive services only. Persistence is explicit and project-first. CoPilot advice remains non-executing.

## Consequences

Future feature implementations share one model, graph, timeline, parameter, validation, rebuild, history, and analytics architecture while existing tests remain independent of native CAD availability.
