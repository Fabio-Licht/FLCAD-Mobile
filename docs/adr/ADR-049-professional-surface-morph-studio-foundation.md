# ADR-049 — Professional Surface Morph Studio Foundation

## Status

Accepted.

## Decision

All professional surface editing enters through `SurfaceMorphApi`. A morph session owns its tool, native target, anchors, constraint groups, influence region, falloff, preview, validation, history and analytics. Preview stores the original native surface ID and never creates replacement geometry.

Morph validation precedes execution and checks topology, continuity, surface quality, affected patches and boundaries, anchors and constraint conflicts. Commit translates the approved intent into Surface Operations, then uses Live Reconstruction and its exclusive `GeometryKernelAPI` boundary. The Morph Engine never calls OpenCascade directly.

Fixed, soft, boundary, surface, curve, point and multi anchors are supported. Linear, smooth, Gaussian, bell and custom-curve falloffs produce deterministic influence weights. Advisor recommendations remain consultative.

The current OpenCascade adapter has no approved surface morph primitive. It therefore returns `UnsupportedOperation: moveBoundary`; the original surface remains unchanged and no fallback is allowed.

## Certification

OpenCascade 8.0.1 processed the official `bearing.stl` through Recognition, Fitting, Topology and Continuity. Two real-target anchors, a smooth influence region, preview and validation passed. Commit returned explicit unsupported status with zero geometry modifications and zero fallbacks.
