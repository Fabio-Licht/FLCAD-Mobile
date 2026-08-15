# ADR-053 — Professional Boundary Editing Suite

## Status

Accepted.

## Decision

Professional Boundary Editing is a Project First transactional layer over Surface Operations → GeometryKernelAPI → OpenCascade 8.0.1 → Live Reconstruction. All eleven editing strategies use the single official kernel operation `editBoundary`; Extend Boundary records its integration with Professional Extend without bypassing that pipeline.

Boundary Analyzer, Preview, Validation and Smart Advisor are non-mutating. Fixed boundary, surface, curve, point, patch and locked-feature regions participate in constraint validation. G0, G1 and G2 are supported policy levels; G3 is reserved.

Without native boundary editing, commit returns exactly `UnsupportedOperation: editBoundary`, preserving native handles, geometry, preview, validation, advisor and history. Simulated geometry, approximation, fallback and processing outside the official pipeline are forbidden. Runtime bootstrap is passive and lazy, without timers, isolates or automatic workers.
