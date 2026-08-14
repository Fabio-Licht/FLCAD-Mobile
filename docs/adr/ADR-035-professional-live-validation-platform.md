# ADR-035 — Professional Live Validation Platform

## Decision

Continuous comparison lives in `live_validation`. Updates are event-driven and incremental; imports and bootstrap never start timers, isolates or workers. The platform calls `GeometryKernelAPI.validate()` through `ValidationKernelAdapter` and never creates geometry.

The existing `meshing` capability gates backend deviation support. Metrics and samples must be returned by the backend; absent or incomplete data produces `UnsupportedOperation`. Recommendations are consultative and never modify CAD state.

## Consequences

Mesh×CAD quality can update only affected regions after Sketch, Feature, Datum, Alignment or Surface events. Snapshots, baseline and timeline preserve measured history without full-part recalculation.
