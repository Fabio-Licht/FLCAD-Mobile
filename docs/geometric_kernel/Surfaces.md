# Surfaces

`ParametricSurface3` defines position, U/V derivatives and normals without introducing B-Rep topology. `PlaneSurface3` is the reference implementation. `SurfaceDifferential` validates regular parameterizations and establishes the curvature API; nonlinear surfaces will provide specialized differential evaluators.
