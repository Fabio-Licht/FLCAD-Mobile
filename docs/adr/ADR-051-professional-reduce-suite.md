# ADR-051 — Professional Reduce Suite

## Status

Accepted.

## Decision

Professional Reduce is a Project First transactional layer over Surface Operations → GeometryKernelAPI → OpenCascade 8.0.1 → Live Reconstruction. All eleven Reduce strategies share the official `reduceSurface` kernel operation.

Preview, Validation and Advisor are non-mutating. Smart and Manufacturing modes remain consultative. Fixed distance, boundary, surface, curve, point and patch regions participate in constraint validation. G0, G1 and G2 are supported policy levels; G3 is reserved infrastructure.

Commit is permitted only after validation. Without native Reduce, it returns exactly `UnsupportedOperation: reduceSurface`, retains the original `ShapeHandle`, and creates no geometry. Morph forwarding, fallbacks, simulated BREP and approximations are forbidden. Runtime initialization is passive and lazy, with no timers, isolates or workers.
