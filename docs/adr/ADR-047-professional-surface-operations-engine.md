# ADR-047 — Professional Surface Operations Engine

## Status

Accepted.

## Decision

Every future surface modification must pass through `SurfaceOperationsApi`: begin, preview, constraint solving, validation, kernel commit and Project First projection. Preview is non-mutating and references the original native handle. Commit is prohibited unless topology, continuity, boundary health, patch health, surface quality and constraints all pass.

The additive `SurfaceOperationKernelAPI` is the only execution boundary. A backend must return a new shape handle plus undo and redo tokens atomically. The current OpenCascade adapter intentionally returns `UnsupportedOperation` because no approved native Move Boundary implementation exists. It never manufactures a result, uses a BREP fallback or changes the source patch.

Committed operations can roll back only through the backend undo token. Cancellation is valid before commit and preserves the original state. History and analytics record every state transition. Advisor output is consultative and cannot execute an operation.

## Consequences

- Move, Extend, Trim, Split, Merge, Offset, Replace, Match, Project Boundary, Reparameterize and Healing have official infrastructure without falsely claiming backend support.
- Anchors, locks, fixed points, tangency, curvature, direction and manufacturing intent are reusable by G-011.
- Bootstrap registration remains passive; loading OpenCascade happens only at kernel execution.
- Six Project First paths persist operations, history, constraints, validation, analytics and reports.

## Certification

OpenCascade 8.0.1 imported the official `bearing.stl` and completed Recognition, Surface Fitting, Topology and Continuity. A Move Boundary preview and validation passed. Commit returned exactly `UnsupportedOperation: moveBoundary`; the original handle remained unchanged and no fallback was used.
