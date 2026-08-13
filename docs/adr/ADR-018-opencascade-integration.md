# ADR-018: OpenCascade Integration

- Status: Accepted with external runtime dependency
- Date: 2026-08-13

## Context

FLCAD needs its first real CAD kernel without exposing OCCT classes or coupling higher layers to a vendor. The current workspace contains no OpenCascade SDK, libraries or native host binary.

## Decision

Integrate OCCT exclusively through `OpenCascadeKernelPlugin`, `OpenCascadeKernelAdapter` and the private `OpenCascadeNativeBridge`. Public values are persistent opaque handles and structured diagnostics. Native calls use the Engineering Runtime queue in local execution mode because native handles and FFI state cannot cross Dart isolates safely.

Register an unavailable bridge by default. It fails health checks and every native operation explicitly until an actual OCCT host is supplied. Tests may use a recording bridge to verify routing and encapsulation, but it is not registered as a production geometry provider.

## Consequences

- Engineering Core, Workflow, Decision, Reconstruction, Studio and FEL remain vendor-neutral.
- Native tokens cannot be serialized or escape the adapter.
- Kernel changes preserve the prior active implementation on failed selection.
- Real STEP/IGES/BREP execution requires building and distributing the external OCCT host.
- No boolean, feature, sketch solver or parametric modeling capability is implied.

