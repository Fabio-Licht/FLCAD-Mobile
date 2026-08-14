# ADR-050 — Professional Extend Suite

## Status

Accepted.

## Decision

All eleven extension methods share `SurfaceExtendApi` and the certified Morph → Surface Operations → GeometryKernelAPI → Live Reconstruction pipeline. The analyzer is non-mutating and predicts distance, angle, direction, affected topology, continuity, reflection, zebra, tension, twist, self-intersection and quality before commit.

Smart Extend only recommends a method; the user retains control. Manufacturing Extend records tooling, die, punch, extraction and draft intent. Validation blocks unsafe reflection, zebra, draft, quality, twist, self-intersection or constraints.

OpenCascade currently has no approved Extend primitive, so commit returns `UnsupportedOperation: moveBoundary`. No alternate BREP or simulated surface is permitted.
