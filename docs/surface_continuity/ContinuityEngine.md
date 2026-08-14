# Continuity Engine

`SurfaceContinuityApi.run` consumes a `SurfaceTopologyReport`. For every real adjacency it compares topology intersection, native average normals and native mean curvature, then records discontinuity, angle, maximum/mean/RMS error, effective continuity and G0/G1/G2 classification. G3 is reserved in the model. Isolated patches are `notApplicable`, never fabricated as continuous.
