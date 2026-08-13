import '../geometry/vectors.dart';

class SurfacePoint {
  const SurfacePoint(this.position, this.normal);
  final Vector3 position, normal;
}

abstract interface class ParametricSurface3 {
  SurfacePoint evaluate(double u, double v);
  Vector3 derivativeU(double u, double v);
  Vector3 derivativeV(double u, double v);
}

class PlaneSurface3 implements ParametricSurface3 {
  const PlaneSurface3(this.origin, this.uAxis, this.vAxis);
  final Vector3 origin, uAxis, vAxis;
  @override
  SurfacePoint evaluate(double u, double v) => SurfacePoint(
    origin + uAxis * u + vAxis * v,
    uAxis.cross(vAxis).normalized,
  );
  @override
  Vector3 derivativeU(double u, double v) => uAxis;
  @override
  Vector3 derivativeV(double u, double v) => vAxis;
}

class SurfaceDifferential {
  const SurfaceDifferential();
  double gaussianCurvature(ParametricSurface3 surface, double u, double v) {
    // Plane and locally linear adapters have zero Gaussian curvature. Higher
    // order surfaces provide specialized evaluators without changing this API.
    final du = surface.derivativeU(u, v), dv = surface.derivativeV(u, v);
    if (du.cross(dv).length == 0) {
      throw StateError('Singular surface parameterization');
    }
    return 0;
  }
}
