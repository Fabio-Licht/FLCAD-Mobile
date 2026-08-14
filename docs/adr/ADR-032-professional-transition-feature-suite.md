# ADR-032 — Professional Transition Feature Suite

## Decision

Sweep and Loft share the `transition_features` domain for models, validation, preview, dependencies, timeline, analytics and persistence. Preparation and preview are kernel-free. Confirmation and rebuild exclusively follow `TransitionFeature -> TransitionFeatureKernelAdapter -> GeometryKernelAPI -> kernel plugin`.

The adapter requires explicit `sweep` or `loft` capability and official input `ShapeHandle` references. Unavailable and unsupported backends return explicit states. No simulated geometry, fallback, or direct OpenCascade access is allowed.

## Consequences

Sixteen professional variants remain parametric and inspectable without a native backend. Kernel execution is transactional and its output remains kernel-owned. Both families participate in the existing Feature Modeling timeline and dependency graphs.
