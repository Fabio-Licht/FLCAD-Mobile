# ADR-052 — Professional Fair & Surface Relax Suite

## Status

Accepted.

## Decision

Professional Fair is a Project First transactional layer over Surface Operations → GeometryKernelAPI → OpenCascade 8.0.1 → Live Reconstruction. All Fair, Relax and optimization modes use the single official kernel operation `fairSurface`.

Preview reuses certified Reflection, Zebra and Curvature analyses and remains non-mutating. Smart Fair, Twist Reduction and Manufacturing Fair are consultative. Fixed boundary, surface, curve, point, patch and radius regions participate in constraint validation. G0, G1 and G2 are supported policy levels; G3 is reserved.

Without native Fair, commit returns exactly `UnsupportedOperation: fairSurface`, preserving the original handle, geometry, history, workflow, preview, validation and advisor. Simulated geometry, approximation, fallback and processing outside the official pipeline are forbidden. Runtime bootstrap is passive and lazy, with no timers, isolates or automatic workers.
