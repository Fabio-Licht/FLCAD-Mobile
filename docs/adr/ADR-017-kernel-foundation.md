# ADR-017: Kernel Foundation

- Status: Accepted
- Date: 2026-08-13

## Context

FLCAD needs future CAD topology without coupling Engineering Core, ERI, Workflow, Studio or FEL to OpenCascade or another vendor. Native types and memory identities would make persistence, testing and alternate kernels fragile.

## Decision

Adopt a plugin-based kernel boundary centered on `GeometryKernelAPI`, `KernelManager` and opaque persistent `ShapeHandle` references. Require explicit capabilities, health checks and transactional operation context. Register the manager in Engineering Runtime and expose administrative operations through FEL.

Factories, validation and healing remain contracts until a real plugin implements them. The unavailable fallback fails explicitly rather than producing placeholder geometry.

## Consequences

- vendor kernels can be added or replaced without changing domain consumers;
- persistent identity and history are independent of native memory;
- unsupported operations remain visible and auditable;
- no real CAD geometry is available from this sprint alone;
- plugin implementations must translate handles and preserve transaction semantics.

