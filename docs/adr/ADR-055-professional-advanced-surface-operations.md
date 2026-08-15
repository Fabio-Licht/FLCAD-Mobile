# ADR-055 — Professional Advanced Surface Operations

## Status

Accepted.

## Decision

Advanced Surface Operations consolidates reconstruction and repair as a Project First orchestration layer over Surface Operations → GeometryKernelAPI → OpenCascade 8.0.1 → Live Reconstruction. It reuses Topology, Continuity, Boundary constraints and Manufacturing Intent; no geometry engine is duplicated.

Gap Analysis, Surface Network Optimization and Smart Surface Advisor are non-mutating and cannot commit. Mutating operations use their explicit native names: `matchSurface`, `replaceSurface`, `rebuildSurface`, `healingOperation`, `stitchSurface`, `fillSurface` and `gapClosure`. Unsupported native operations preserve handles, geometry, preview, validation, advisor and history and return the kernel diagnostic unchanged.

G0, G1 and G2 are supported policy levels; G3 is reserved. Simulated geometry, approximations and parallel pipelines are forbidden. Runtime bootstrap is passive and lazy, without timers, isolates or automatic workers.
