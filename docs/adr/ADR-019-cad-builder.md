# ADR-019: CAD Builder

- Status: Accepted with external OCCT runtime dependency
- Date: 2026-08-13

## Context

FLCAD needs its first real B-Rep construction workflow while keeping domain, UI and engineering intelligence independent of OpenCascade.

## Decision

Create a project-scoped CAD Builder domain over `GeometryKernelAPI`. Typed builders delegate every native construction request to the selected kernel. `CadBuilderEngine` wraps each request in a transaction, validates before commit, maintains a persistent dependency graph, writes portable records and captures history and analytics.

Extend the private OpenCascade bridge with generic shape construction. Native tokens remain inside `OpenCascadeKernelAdapter`; only persistent handles, fingerprints, metadata and diagnostics cross the boundary.

Require explicit closed-shell evidence before requesting a Solid. Never persist an invalid entity.

## Consequences

- Workflow, Decision, Reconstruction and Studio can use a shared project-scoped factory.
- Projects store shapes under `CAD/Shapes` and topology under `CAD/Topology`.
- Undo removes the portable entity record and retains its audit event.
- Real B-Rep execution still requires the external OCCT native host absent from this workspace.
- Extrude, Revolve, Sweep, Loft, booleans, fillet, chamfer and parametric features remain unsupported.

