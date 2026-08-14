# ADR-042 — Professional Mesh Foundation

## Status

Accepted.

## Decision

STL is imported exclusively by OpenCascade `RWStl` into a native `Poly_Triangulation`. Mesh lifetime is independent from BRep shape lifetime and is exposed through the additive `MeshGeometryKernelAPI`. `MeshEntity` stores the persistent handle and Project First metadata; it never copies or simulates geometry.

Import explicitly updates Workflow, Session, Dashboard and Project through `OfficialMeshIntegration`, then leaves Recognition idle. Bootstrap only registers passive services and never loads the DLL.
