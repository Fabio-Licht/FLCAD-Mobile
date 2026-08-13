# ADR-022: Automatic Surface Generation

- Status: Accepted with external OCCT runtime dependency
- Date: 2026-08-13

## Context

Surface Intelligence can now decide what should be built, but FLCAD needs a controlled boundary that turns approved analytical candidates into kernel operations without bypassing validation, audit or vendor encapsulation.

## Decision

Create `surface_generation` as the sole orchestration pipeline for Plane, Cylinder, Cone and Sphere generation. Require complete candidate parameters and an active declared kernel capability. Execute construction through `GeometryKernelAPI`, validate the returned handle, collect non-mutating healing/sewing/repair proposals, then register and integrate the result.

Persist invalid and unavailable attempts for traceability, but never insert them into Surface Registry or Engineering Graph. Keep native calls on the local runtime queue.

## Consequences

- planning and geometry generation remain distinct and auditable;
- no OpenCascade type escapes its private adapter;
- absent backend produces explicit diagnostics with no fictitious handle;
- generated surfaces are Project First and available to Studio, Decision and Reconstruction consumers;
- NURBS, Patch, Blend, Loft, Sweep, Trim, Freeform, Extension, Matching and Surface Network remain unsupported.

