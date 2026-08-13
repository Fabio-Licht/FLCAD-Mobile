import 'dart:math' as math;
import '../../smart_regions/models/geometry.dart';
import '../models/adaptive_surface.dart';
import '../models/surface_geometry.dart';
import 'surface_builder.dart';

SurfaceMetrics metrics(
  List<double> errors,
  int count, {
  double curvature = 0,
  double continuity = 1,
}) {
  final mean = errors.isEmpty
          ? 0.0
          : errors.reduce((a, b) => a + b) / errors.length,
      rms = errors.isEmpty
          ? 0.0
          : math.sqrt(
              errors.fold<double>(0, (a, b) => a + b * b) / errors.length,
            ),
      max = errors.fold<double>(0, math.max);
  return SurfaceMetrics(
    rmsError: rms,
    maxError: max,
    meanError: mean,
    averageCurvature: curvature,
    continuity: continuity,
    confidence: (count / 50).clamp(.1, 1).toDouble(),
    pointCount: count,
  );
}

Vec3 centroid(List<Vec3> points) =>
    points.fold<Vec3>(const Vec3(0, 0, 0), (a, b) => a + b) /
    points.length.toDouble();

class PlaneSurfaceBuilder implements SurfaceBuilder {
  @override
  String get id => 'plane-fit';
  @override
  Set<SurfaceKind> get supportedKinds => const {SurfaceKind.plane};
  @override
  Future<SurfaceCandidate> build(SurfaceBuildRequest r) async {
    if (r.samples.length < 3) {
      throw ArgumentError('Plane requires at least three points');
    }
    final center = centroid(r.samples),
        normal = ((r.samples[1] - r.samples[0]).cross(
          r.samples[2] - r.samples[0],
        )).normalized;
    if (normal.length == 0) throw ArgumentError('Collinear plane samples');
    final errors = r.samples
        .map((p) => (p - center).dot(normal).abs())
        .toList();
    return SurfaceCandidate(
      solverId: id,
      geometry: ParametricSurfaceGeometry(SurfaceKind.plane, {
        'ox': center.x,
        'oy': center.y,
        'oz': center.z,
        'nx': normal.x,
        'ny': normal.y,
        'nz': normal.z,
      }),
      metrics: metrics(errors, r.samples.length),
      complexity: .1,
    );
  }
}

class SphereSurfaceBuilder implements SurfaceBuilder {
  @override
  String get id => 'sphere-fit';
  @override
  Set<SurfaceKind> get supportedKinds => const {SurfaceKind.sphere};
  @override
  Future<SurfaceCandidate> build(SurfaceBuildRequest r) async {
    if (r.samples.length < 4) {
      throw ArgumentError('Sphere requires at least four points');
    }
    final center = centroid(r.samples),
        distances = r.samples.map((p) => (p - center).length).toList(),
        radius = distances.reduce((a, b) => a + b) / distances.length,
        errors = distances.map((d) => (d - radius).abs()).toList();
    return SurfaceCandidate(
      solverId: id,
      geometry: ParametricSurfaceGeometry(SurfaceKind.sphere, {
        'cx': center.x,
        'cy': center.y,
        'cz': center.z,
        'radius': radius,
      }),
      metrics: metrics(
        errors,
        r.samples.length,
        curvature: radius == 0 ? 0.0 : 1 / radius,
      ),
      complexity: .2,
    );
  }
}

class PatchSurfaceBuilder implements SurfaceBuilder {
  @override
  String get id => 'adaptive-patch';
  @override
  Set<SurfaceKind> get supportedKinds => const {
    SurfaceKind.patch,
    SurfaceKind.nurbs,
    SurfaceKind.bezier,
    SurfaceKind.bSpline,
    SurfaceKind.fill,
    SurfaceKind.coons,
    SurfaceKind.gordon,
    SurfaceKind.subdivision,
  };
  @override
  Future<SurfaceCandidate> build(SurfaceBuildRequest r) async {
    if (r.samples.length < 3) throw ArgumentError('Patch requires samples');
    final kind = r.targetKind ?? SurfaceKind.patch,
        degree = math.min(
          5,
          math.max(1, math.sqrt(r.samples.length).floor() - 1),
        );
    return SurfaceCandidate(
      solverId: id,
      geometry: ParametricSurfaceGeometry(
        kind,
        const {},
        controlPoints: r.samples,
        degreeU: degree,
        degreeV: degree,
      ),
      metrics: metrics(const [], r.samples.length, continuity: .8),
      complexity: (degree * degree) / 25.0,
    );
  }
}
