# ADR-031 — Professional Revolve Feature

## Decision

Revolve is a parametric feature owned by `revolve_feature`. Preparation and preview are kernel-free. Confirmation and rebuild exclusively use `GeometryKernelAPI` through `RevolveFeatureKernelAdapter`, transactions, and official `ShapeHandle` results.

The feature platform owns timeline and dependency state. Missing kernels return `KernelUnavailable`; kernels without `KernelCapability.revolve` return `UnsupportedOperation`. No simulated or fallback geometry is permitted.

## Consequences

All fourteen variants share one model and validation pipeline. Axis, parameter, history, graph, preview, analytics and persistence state remain inspectable without loading a native backend. A native plugin must explicitly advertise Revolve before geometry execution is possible.
