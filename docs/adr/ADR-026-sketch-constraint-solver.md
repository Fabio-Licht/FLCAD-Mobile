# ADR-026 — Sketch Constraint Solver

## Status

Accepted.

## Decision

Constraint solving is a separate `sketch_constraints` domain. It consumes parametric Sketch entities but has no dependency on GeometryKernelAPI, OpenCascade, BRep, NURBS, surfaces, or feature generation.

The first solver is deterministic and incremental: mutations mark a constraint and its downstream dependencies dirty; solves may process the dirty set or an explicit subset. Priority controls queue order. Cycles, missing references, duplicates, conflicts, overdefinition, and underdefinition produce domain diagnostics. Transactions snapshot constraint, dimension, graph, and analytics state for rollback and undo/redo.

Bootstrap registers factories and state services without initialization or persistence side effects. All persisted data remains below the project `CAD` directory.

## Consequences

Sketch intent can now be constrained and diagnosed without native CAD geometry. Numerical general-purpose solving and visual dimension rendering remain future work.
