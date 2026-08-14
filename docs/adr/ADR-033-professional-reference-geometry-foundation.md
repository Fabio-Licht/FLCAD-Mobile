# ADR-033 — Professional Reference Geometry Foundation

## Decision

Reference geometry is owned by the independent `reference_geometry` domain. Definitions, previews, graphs and workspace state are parametric and kernel-free. Confirmation exclusively follows `Reference Platform -> ReferenceKernelAdapter -> GeometryKernelAPI -> kernel plugin`.

The existing `planeSurface` capability gates the official reference adapter to avoid changing shared kernel contracts. Unsupported or unavailable backends return explicit states. No simulated geometry or direct OpenCascade access is permitted.

## Consequences

Ten reference families and their construction methods can support alignment and reverse-engineering workflows before a native backend is loaded. Persistent IDs and the independent dependency graph preserve downstream stability.
