# Surface-aware Sketch

`SurfaceSketchAdapter`, `SurfaceDomain` e `SurfaceCurveProjector` definem projeção, normal e continuidade sobre plano, cilindro, cone, esfera e futuros Torus/NURBS. O núcleo não gera superfícies.

Multi Surface Sketch é suportado pelo modelo: cada anchor aponta para seu próprio contexto. Um `HybridGeometryKernel` poderá transferir anchors entre domínios preservando continuidade e identidade.
