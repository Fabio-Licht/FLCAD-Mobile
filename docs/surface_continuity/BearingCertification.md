# G-010E Bearing Certification

Status: **APPROVED**

The exclusive input was the OCCT 8.0.1 `data/stl/bearing.stl`. The official pipeline executed Mesh Foundation → Recognition → Surface Fitting → Topology → Continuity Analysis through `GeometryKernelAPI` and the Release OpenCascade bridge.

- Mesh: 12,405 vertices; 24,680 triangles; checksum `fnv1a64:4e808945d73b9af2`.
- Reconstructed patches analyzed: 1.
- Continuity: G0 0, G1 0, G2 0, `notApplicable` 1 (the patch has no shared patch boundary).
- Overall quality score: `0.7731026170014186`.
- Curvature, reflection, zebra and draft: sampled natively from the real `TopoDS_Face`.
- Geometry modifications, solids and fallbacks: 0.

The machine-readable evidence is generated at `build/certification/g010e-surface-continuity/G010E-Certification.json`.
