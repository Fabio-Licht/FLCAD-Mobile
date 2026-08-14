# ADR-043 — Professional Surface Recognition Engine

## Status

Accepted.

## Decision

Surface Recognition consumes the real `Poly_Triangulation` retained by Mesh Foundation through the additive, read-only `MeshGeometryKernelAPI.inspectMesh` boundary. Node and triangle buffers are copied by the OpenCascade adapter; no STL parser, BRep fallback or duplicate geometry store exists.

The deterministic pipeline is: face normals, local curvature, edge-topology adjacency, incremental region growing, small-region merge, region graph, competing least-squares primitive fits, multi-factor confidence, report and consultative advisor. It never creates CAD.

Runtime initialization is explicit on `run`; bootstrap remains passive and never loads the native library. Stable region IDs derive from mesh checksum plus ordered region index, while report IDs use `IdGenerator`.

## Consequences

Plane, cylinder, cone, sphere and torus candidates compete by normalized RMS, stability, coverage and separation. Failed thresholds produce Freeform or Unknown instead of fabricated certainty. Project First owns persisted recognition artifacts under `CAD/Recognition*`.
