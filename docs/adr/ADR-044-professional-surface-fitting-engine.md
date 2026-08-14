# ADR-044 — Professional Surface Fitting Engine

## Status

Accepted.

## Decision

Surface Fitting consumes primitive regions from G-010B and their real native mesh vertices. Deterministic RANSAC sampling, robust weighted least squares and iterative residual refinement produce mathematical parameters and residual evidence before geometry creation.

Only accepted primitive fits call `GeometryKernelAPI.create`. The OpenCascade adapter exports Plane, Cylinder, Cone, Sphere and Torus as real `TopoDS_Face` values. Freeform, Unknown and rejected fits have no handle and no fallback. Runtime and kernel loading remain lazy.

Surface entities retain the recognition-region identity, OCCT handle, parameters, bounds, area, residual statistics, confidence, health and timestamp. Project First persists all artifacts below `CAD/Surface*`.
