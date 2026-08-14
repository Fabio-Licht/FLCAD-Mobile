# ADR-034 — Professional Alignment Suite

## Decision

Alignment definitions, transforms, previews and metrics live in the independent `alignment_engine` domain. `Apply` is provisional and never changes definitive model position. Only explicit `Commit` follows `Alignment Platform -> AlignmentKernelAdapter -> GeometryKernelAPI -> kernel plugin`.

The existing `brep` capability gates official shape transformation, preserving public kernel contracts. Unsupported or unavailable backends return explicit states. No simulated geometry or direct OpenCascade access is allowed.

## Consequences

Sixteen alignment strategies share references, matrices, graph, history, quality and analytics. Alignment can be reviewed, cancelled or rolled back before downstream CAD state changes.
