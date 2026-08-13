# Feature Engine

`FeatureEngine` is the project-scoped orchestrator for high-level CAD operations. It accepts only opaque `ShapeHandle` inputs, checks kernel capabilities, opens a kernel transaction, delegates construction through `GeometryKernelAPI`, validates the output and persists only valid results.

Extrude, Revolve, Sweep, Loft, booleans, Offset, Shell, Draft, Mirror and Pattern share this pipeline. Missing capabilities produce an explicit `unavailable` feature with no output geometry.

