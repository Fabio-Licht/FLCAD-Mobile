# ADR-048 — Professional Live Surface Reconstruction Engine

## Status

Accepted. G-010 is closed and certified.

## Decision

Reverse-engineering updates use one incremental pipeline after Surface Operations. A permanent dependency graph relates recognition regions, patches, boundaries, continuity assessments and patch-scoped reflection, zebra, draft, heat-map, validation and analytics projections. The affected-object calculator starts only from IDs declared by the operation preview. The scheduler is forbidden from emitting an ID outside that set and its downstream dependencies.

Preview records the original native surface IDs and declares `fullProjectRecalculation: false`. Validation verifies the operation, affected scope, graph membership and baseline identity. Update invalidates and schedules only affected projections. Commit delegates to `SurfaceOperationsApi`, whose only execution boundary is `SurfaceOperationKernelAPI`/`GeometryKernelAPI`. Rollback restores the preview snapshot and, after a supported commit, uses the backend undo token.

No timer, worker, isolate or native library starts at import or bootstrap. Advisor output is consultative. The project, workflow, session, Studio, Engineering Intelligence and Live Validation receive Project First projections only.

## Certification

The OpenCascade 8.0.1 `bearing.stl` completed import, Recognition, Surface Fitting, Topology, Continuity, Surface Operations preview, Live Reconstruction, validation, advisor, analytics and rollback. One patch and 12 dependent objects were scheduled; full-project recalculation was false. The final commit returned `UnsupportedOperation: moveBoundary`, preserved the original handle and created no fake geometry or fallback.
