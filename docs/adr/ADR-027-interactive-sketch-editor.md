# ADR-027 — Interactive Sketch Editor

## Status

Accepted.

## Decision

Interactive sketch editing lives in `core/sketch_editor`, above the parametric Sketch Engine and Constraint Solver. Creation and editing require a transient preview before confirmation. Confirmed operations use Sketch transactions, history, graph records, undo/redo, selection, snapping, and analytics.

The editor reads degrees of freedom and diagnostics from G-006B; it does not introduce another solver. Rendering is a set of presentation states and styles, never OpenCascade geometry. The Engineering CoPilot produces explainable recommendations only and cannot execute them.

Runtime initialization and persistence are explicit. Bootstrap registration starts no editor and creates no project directory.

## Consequences

FLCAD gains a professional parametric editing contract without coupling interaction to GeometryKernelAPI, BRep, CAD features, or surface modeling.
