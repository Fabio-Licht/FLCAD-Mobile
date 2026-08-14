# ADR-025 — Sketch Engine Foundation

## Status

Accepted.

## Decision

FLCAD owns a project-first, parametric Sketch Engine under `core/sketch_engine`. It stores intent and parameters only. The domain does not import OpenCascade, produce BRep, or invoke `GeometryKernelAPI`; conversion to definitive CAD geometry is a later integration.

Sketches, entities, history, graphs, and analytics have separate persistence areas below `CAD/`. Mutations are transactional and snapshot-backed so rollback, undo, and redo preserve the whole domain state. Sketch graphs remain independent from `EngineeringGraph`.

Runtime initialization is explicit. Bootstrap registers contracts and factories but performs no I/O and starts no worker. Constraint solving and feature generation are deliberately excluded from G-006A.

## Consequences

User-visible sketch intent can be created, selected, inspected, versioned, and persisted without a native CAD backend. Kernel conversion, constraints, NURBS, and BRep require later ADRs.
