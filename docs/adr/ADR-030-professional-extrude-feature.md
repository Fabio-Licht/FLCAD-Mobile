# ADR-030 — Professional Extrude Feature

## Status

Accepted.

## Decision

Extrude is the first implemented Feature family on the G-007A platform. Preparation and preview remain parametric. Confirmation alone may invoke `GeometryKernelAPI`, through `FeatureKernelAdapter` and a kernel transaction.

Execution requires a recognized profile plus an official kernel `ShapeHandle`. The system never converts a logical profile through a parallel geometry path. An unavailable backend returns `KernelUnavailable`; a backend without `KernelCapability.extrude` returns `UnsupportedOperation`. Neither outcome creates a shape.

OpenCascade currently does not advertise Extrude capability, so its result remains explicitly unsupported until its native bridge implements that operation. Test kernels verify the official supported pipeline without adding production fallback geometry.

## Consequences

All Extrude modes share validation, preview, timeline, dependencies, history, analytics and persistence while definitive geometry remains owned exclusively by the selected native backend.
