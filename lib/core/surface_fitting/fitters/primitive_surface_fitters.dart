import 'dart:math' as math;

import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_kernel/services/fitting_engine.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../../surface_recognition/models/surface_recognition_models.dart';
import '../models/surface_fitting_models.dart';
import '../optimization/deterministic_optimizer.dart';

abstract interface class ProfessionalSurfaceFitter {
  PrimitiveType get type;
  SurfaceFitCandidate fit(SurfaceClassification region, List<Vector3> points);
}

abstract class BaseSurfaceFitter implements ProfessionalSurfaceFitter {
  const BaseSurfaceFitter();
  final optimizer = const DeterministicSurfaceOptimizer();
  SurfaceFitCandidate result(
    SurfaceClassification region,
    Map<String, dynamic> parameters,
    List<double> residuals,
  ) {
    final stats = optimizer.analyze(residuals),
        scale = _scale(region),
        normalized = stats.rms / scale;
    final confidence =
        (1 / (1 + normalized * 100) * .75 + region.confidence * .25).clamp(
          0.0,
          1.0,
        );
    return SurfaceFitCandidate(
      regionId: region.region.id,
      type: type,
      parameters: parameters,
      residuals: stats,
      confidence: confidence,
      valid: stats.rms.isFinite && confidence >= .45,
      algorithm:
          'deterministic RANSAC + weighted least squares + iterative residual refinement',
    );
  }

  double _scale(SurfaceClassification c) {
    final b = c.region.bounds;
    return math.max(
      math.sqrt(
        math.pow(b.maxX - b.minX, 2) +
            math.pow(b.maxY - b.minY, 2) +
            math.pow(b.maxZ - b.minZ, 2),
      ),
      1e-12,
    );
  }

  Vector3 vector(Object? value) =>
      Vector3.fromJson((value as List).cast<dynamic>());
  List<Vector3> inliers(List<Vector3> points, List<double> residuals) {
    final stats = optimizer.analyze(residuals),
        limit = math.max(stats.rms * 2.5, 1e-12);
    final values = [
      for (var i = 0; i < points.length; i++)
        if (residuals[i].abs() <= limit) points[i],
    ];
    return values.length >= 3 ? values : points;
  }
}

class PlaneSurfaceFitter extends BaseSurfaceFitter {
  const PlaneSurfaceFitter();
  @override
  PrimitiveType get type => PrimitiveType.plane;
  @override
  SurfaceFitCandidate fit(SurfaceClassification region, List<Vector3> points) {
    var fit = const FittingEngine().fitPlane(points);
    var residuals = points.map((p) => fit.geometry.signedDistance(p)).toList();
    final robust = inliers(points, residuals);
    if (robust.length >= 3) fit = const FittingEngine().fitPlane(robust);
    residuals = points.map((p) => fit.geometry.signedDistance(p)).toList();
    final b = region.region.bounds,
        extent = math.max(
          b.maxX - b.minX,
          math.max(b.maxY - b.minY, b.maxZ - b.minZ),
        );
    return result(region, {
      'origin': fit.geometry.origin.toJson(),
      'normal': fit.geometry.normal.toJson(),
      'lowerBound': -extent,
      'upperBound': extent,
    }, residuals);
  }
}

class SphereSurfaceFitter extends BaseSurfaceFitter {
  const SphereSurfaceFitter();
  @override
  PrimitiveType get type => PrimitiveType.sphere;
  @override
  SurfaceFitCandidate fit(SurfaceClassification region, List<Vector3> points) {
    var fit = const FittingEngine().fitSphere(points);
    var residuals = points
        .map((p) => fit.geometry.center.distanceTo(p) - fit.geometry.radius)
        .toList();
    final robust = inliers(points, residuals);
    if (robust.length >= 4) fit = const FittingEngine().fitSphere(robust);
    final radii = points.map(fit.geometry.center.distanceTo).toList(),
        weights = optimizer.robustWeights(
          radii.map((r) => r - fit.geometry.radius).toList(),
        );
    final radius = optimizer.weightedMean(radii, weights);
    residuals = radii.map((r) => r - radius).toList();
    return result(region, {
      'center': fit.geometry.center.toJson(),
      'radius': radius,
      'lowerBound': -math.pi / 2,
      'upperBound': math.pi / 2,
    }, residuals);
  }
}

class CylinderSurfaceFitter extends BaseSurfaceFitter {
  const CylinderSurfaceFitter();
  @override
  PrimitiveType get type => PrimitiveType.cylinder;
  @override
  SurfaceFitCandidate fit(SurfaceClassification region, List<Vector3> points) {
    final axis = vector(region.parameters['axis']).normalized,
        origin = vector(region.parameters['origin']);
    final axial = points.map((p) => (p - origin).dot(axis)).toList();
    final radii = points
        .asMap()
        .entries
        .map((e) => ((e.value - origin) - axis * axial[e.key]).length)
        .toList();
    var radius = (region.parameters['radius'] as num).toDouble();
    for (var iteration = 0; iteration < 4; iteration++) {
      final residuals = radii.map((r) => r - radius).toList();
      radius = optimizer.weightedMean(
        radii,
        optimizer.robustWeights(residuals),
      );
    }
    return result(region, {
      'axisOrigin': origin.toJson(),
      'axisDirection': axis.toJson(),
      'radius': radius,
      'lowerBound': axial.reduce(math.min),
      'upperBound': axial.reduce(math.max),
    }, radii.map((r) => r - radius).toList());
  }
}

class ConeSurfaceFitter extends BaseSurfaceFitter {
  const ConeSurfaceFitter();
  @override
  PrimitiveType get type => PrimitiveType.cone;
  @override
  SurfaceFitCandidate fit(SurfaceClassification region, List<Vector3> points) {
    final axis = vector(region.parameters['axis']).normalized,
        apex = vector(region.parameters['apex']);
    final axial = points.map((p) => (p - apex).dot(axis)).toList();
    final radial = points
        .asMap()
        .entries
        .map((e) => ((e.value - apex) - axis * axial[e.key]).length)
        .toList();
    var slope = math.tan((region.parameters['angle'] as num).toDouble());
    for (var iteration = 0; iteration < 4; iteration++) {
      final residuals = [
            for (var i = 0; i < points.length; i++)
              radial[i] - axial[i] * slope,
          ],
          weights = optimizer.robustWeights(residuals);
      var numerator = 0.0, denominator = 0.0;
      for (var i = 0; i < points.length; i++) {
        numerator += weights[i] * axial[i] * radial[i];
        denominator += weights[i] * axial[i] * axial[i];
      }
      if (denominator > 1e-18) slope = numerator / denominator;
    }
    final angle = math.atan(slope.abs());
    return result(
      region,
      {
        'apex': apex.toJson(),
        'axisDirection': axis.toJson(),
        'semiAngle': angle,
        'lowerBound': axial.reduce(math.min),
        'upperBound': axial.reduce(math.max),
      },
      [
        for (var i = 0; i < points.length; i++)
          radial[i] - axial[i].abs() * slope.abs(),
      ],
    );
  }
}

class TorusSurfaceFitter extends BaseSurfaceFitter {
  const TorusSurfaceFitter();
  @override
  PrimitiveType get type => PrimitiveType.torus;
  @override
  SurfaceFitCandidate fit(SurfaceClassification region, List<Vector3> points) {
    final axis = vector(region.parameters['axis']).normalized,
        center = vector(region.parameters['center']);
    var major = (region.parameters['majorRadius'] as num).toDouble(),
        minor = (region.parameters['minorRadius'] as num).toDouble();
    for (var iteration = 0; iteration < 4; iteration++) {
      final tube = <double>[];
      for (final p in points) {
        final d = p - center, z = d.dot(axis), radial = (d - axis * z).length;
        tube.add(math.sqrt(math.pow(radial - major, 2) + z * z));
      }
      minor = optimizer.weightedMean(
        tube,
        optimizer.robustWeights(tube.map((e) => e - minor).toList()),
      );
    }
    final residuals = <double>[];
    for (final p in points) {
      final d = p - center, z = d.dot(axis), radial = (d - axis * z).length;
      residuals.add(math.sqrt(math.pow(radial - major, 2) + z * z) - minor);
    }
    return result(region, {
      'center': center.toJson(),
      'axisDirection': axis.toJson(),
      'majorRadius': major,
      'minorRadius': minor,
    }, residuals);
  }
}
