# G-010B Bearing Surface Recognition Certification

## Status

APPROVED.

## Native evidence

- Source: OCCT SDK `bearing.stl`
- Backend: OpenCascade 8.0.1 / `RWStl::ReadFile`
- Representation: `Poly_Triangulation`
- Vertices: 12,405
- Triangles: 24,680
- Checksum: `fnv1a64:4e808945d73b9af2`
- Recognition input: native node and indexed-triangle buffers through `MeshGeometryKernelAPI.inspectMesh`

## Recognition result

- Regions: 2 topologically disconnected regions
- Distribution: 1 Freeform, 1 Cylinder
- Average confidence: 60.63%
- Stable region colors, confidence map, region graph, tree, analytics, report, advisor and Property Inspector: verified
- Project, Session, Workflow, Interactive Reverse, Engineering Studio, Engineering Intelligence and Live Validation projections: verified
- CAD geometry created: no

The machine-readable certificate and Project First artifacts are emitted under `build/certification/g010b-surface-recognition` by `tool/surface_recognition_certification.dart`.
