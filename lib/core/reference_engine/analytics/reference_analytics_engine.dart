import 'dart:math' as math;

import '../../smart_regions/models/geometry.dart';
import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

class ReferenceAnalyticsEngine {
  const ReferenceAnalyticsEngine();

  ReferenceAnalytics evaluate(
    ReferenceGeometry geometry,
    List<Vec3> samples, {
    double areaUsed = 0,
    double coverage = 1,
    double sourceConfidence = 1,
  }) {
    final deviations = samples
        .map((point) => _distance(geometry, point))
        .toList();
    final rms = deviations.isEmpty
        ? 0.0
        : math.sqrt(
            deviations.fold<double>(0, (sum, d) => sum + d * d) /
                deviations.length,
          );
    final maximum = deviations.fold<double>(0, math.max);
    final density = math.min(1.0, samples.length / 50);
    final confidence = (sourceConfidence * .45 + coverage * .3 + density * .25)
        .clamp(0.0, 1.0);
    return ReferenceAnalytics(
      precision: 1 / (1 + rms),
      rmsError: rms,
      maxDeviation: maximum,
      confidence: confidence,
      fitQuality: 1 / (1 + maximum),
      areaUsed: areaUsed,
      coverage: coverage.clamp(0, 1),
      pointCount: samples.length,
    );
  }

  double _distance(ReferenceGeometry geometry, Vec3 point) =>
      switch (geometry) {
        PlaneGeometry g => (point - g.origin).dot(g.normal).abs(),
        AxisGeometry g => (point - g.origin).cross(g.direction).length,
        PointGeometry g => (point - g.position).length,
        CurveGeometry g =>
          g.points.map((p) => (point - p).length).reduce(math.min),
        CoordinateSystemGeometry g => (point - g.origin).length,
      };
}
