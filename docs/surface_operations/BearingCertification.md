# G-010F Bearing Certification

Status: **APPROVED**

The official OpenCascade 8.0.1 `bearing.stl` completed Mesh → Recognition → Surface Fitting → Topology → Continuity. The platform created a Move Boundary operation and a non-mutating preview, then passed topology, continuity, boundary, patch, quality and constraint validation.

OpenCascade does not yet expose an approved Move Boundary implementation, so commit returned `UnsupportedOperation: moveBoundary`. The original native surface handle was preserved. Geometry modifications and fallbacks: 0.

Machine-readable evidence: `build/certification/g010f-surface-operations/G010F-Certification.json`.
