# ADR-024 — OpenCascade Native Runtime

## Decision

OCCT is an optional plugin behind `GeometryKernelAPI`. A narrow C ABI and opaque tokens isolate ABI-sensitive C++ objects from Dart and business domains.

## Consequences

- Backend absence is explicit and does not disable the remaining platform.
- Capabilities are discovered at runtime.
- Geometry operations remain traceable and auditable.
- Building requires a compatible OCCT SDK.
