# ADR-056 — Professional Surface Modeling Certification

## Status

Accepted.

## Decision

G-011H adds no modeling capability. Certification consumes native evidence and fails closed. Approval requires OpenCascade 8.0.1, `bearing.stl`, 500 deterministic pipelines, 500 previews, validations and rollbacks, all G-011 modules, invariant native handles, zero geometry simulation/fallbacks, correct `UnsupportedOperation` diagnostics, an acyclic dependency graph and every architecture/runtime/workspace/persistence/quality check passing.

Missing native evidence yields `requiresNativeRun`; partial or contradictory native evidence yields `rejected`. Only complete 100% evidence yields `approved`. Scores are derived from findings and are never filled with assumed values.
