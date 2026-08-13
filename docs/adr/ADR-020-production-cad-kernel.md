# ADR-020: Production CAD Kernel

- Status: Accepted with external OCCT runtime dependency
- Date: 2026-08-13

## Context

FLCAD needs parametric features and booleans without allowing OpenCascade concepts to propagate into Engineering Core, Studio, Workflow or FEL. Rebuild must be incremental, traceable and safe when a backend is absent.

## Decision

Create `core/cad_features` over `GeometryKernelAPI` and opaque handles. Represent each operation as a versioned `CadFeature` in an independent acyclic graph. Validate capabilities before execution, use kernel transactions, persist only valid outputs and represent unsupported backends as explicit unavailable results.

Rebuild only the shape-affected downstream subgraph, remapping output handles while preserving human decisions. Run native operations through the local Engineering Runtime queue. Extend the private OCC bridge through the existing generic shape-operation boundary; no vendor type crosses the adapter.

## Consequences

- feature history and graph remain portable across future kernels;
- failed and unavailable operations are explainable and auditable;
- the Studio can show feature intent even when execution is unavailable;
- actual feature geometry requires the external OCCT host absent from this workspace;
- no restricted advanced modeling, manufacturing or analysis capability is implied.

