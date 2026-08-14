# ADR-041 — Platform Certification

## Status

Accepted.

## Decision

Certification is evidence-based. Missing architectural evidence blocks a check, and any failed official API step fails the demonstration. A real, non-empty part file and every mandatory workflow step are required. The engine does not substitute callbacks, geometry, kernels or production fallbacks and never starts work during bootstrap.

## Certification history

G-009E initially returned **BLOCKED** because the official kernel IO supported STEP, IGES and BREP but had no Project First STL path.

G-010A resolved the root cause by adding `MeshGeometryKernelAPI`, an OpenCascade `RWStl` adapter, native `Poly_Triangulation` lifetime, `MeshEntity`, repository persistence and official Workflow/Session/Studio projections. G-009E.1 reran the real `bearing.stl` flow and all architecture and integration evidence passed.

The platform status is now **APPROVED** for G-010B — Professional Surface Recognition Engine.
