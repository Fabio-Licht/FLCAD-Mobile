import '../../smart_regions/models/geometry.dart';
import 'reference_builder.dart';
import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

class PlaneBuilder implements ReferenceBuilder {
  @override
  String get id => 'plane';
  @override
  Future<ReferenceBuildResult> build(
    ReferenceBuildContext c,
    ReferenceRecipe r,
  ) async {
    final method = r.parameters['method'] as String? ?? 'region';
    return switch (method) {
      'region' || 'bestFit' => _region(c, r),
      'threePoints' => _three(r),
      'offset' => _offset(c, r),
      'parallel' => _parallel(c, r),
      'perpendicular' => _perpendicular(c, r),
      'mid' => _mid(c, r),
      'tangent' || 'section' => _region(c, r),
      _ => throw UnsupportedError('Plane method $method'),
    };
  }

  ReferenceBuildResult _region(ReferenceBuildContext c, ReferenceRecipe r) {
    final region = c.regions[r.sourceIds.first];
    if (region == null) throw StateError('Region source missing');
    final g = PlaneGeometry(
      region.statistics.centroid,
      region.statistics.averageNormal,
    );
    final rms = region.statistics.averageCurvature;
    return ReferenceBuildResult(
      g,
      ReferenceAnalytics(
        precision: 1 / (1 + rms),
        rmsError: rms,
        maxDeviation: rms * 2,
        confidence: region.confidence,
        fitQuality: (1 - rms).clamp(0, 1),
        areaUsed: region.statistics.area,
        coverage: 1,
        pointCount: region.vertexCount,
      ),
      region.dna.hash,
    );
  }

  ReferenceBuildResult _three(ReferenceRecipe r) {
    final p = (r.parameters['points'] as List)
        .map((e) => Vec3.fromJson(e as List))
        .toList();
    if (p.length != 3) throw ArgumentError('Three points required');
    final normal = (p[1] - p[0]).cross(p[2] - p[0]).normalized;
    if (normal.length == 0) throw ArgumentError('Points are collinear');
    return ReferenceBuildResult(
      PlaneGeometry(p[0], normal),
      const ReferenceAnalytics(
        precision: 1,
        rmsError: 0,
        maxDeviation: 0,
        confidence: 1,
        fitQuality: 1,
        areaUsed: 0,
        coverage: 1,
        pointCount: 3,
      ),
      p.toString(),
    );
  }

  ReferenceBuildResult _offset(ReferenceBuildContext c, ReferenceRecipe r) {
    final base = c.references[r.sourceIds.first]?.geometry;
    if (base is! PlaneGeometry) throw StateError('Plane source required');
    final distance = (r.parameters['distance'] as num).toDouble();
    return ReferenceBuildResult(
      PlaneGeometry(
        base.origin +
            Vec3(
              base.normal.x * distance,
              base.normal.y * distance,
              base.normal.z * distance,
            ),
        base.normal,
      ),
      const ReferenceAnalytics(
        precision: 1,
        rmsError: 0,
        maxDeviation: 0,
        confidence: 1,
        fitQuality: 1,
        areaUsed: 0,
        coverage: 1,
        pointCount: 1,
      ),
      '${r.sourceIds.first}:$distance',
    );
  }

  ReferenceBuildResult _parallel(ReferenceBuildContext c, ReferenceRecipe r) =>
      _offset(
        c,
        ReferenceRecipe(r.builderId, {
          ...r.parameters,
          'distance': r.parameters['distance'] ?? 0,
        }, r.sourceIds),
      );
  ReferenceBuildResult _perpendicular(
    ReferenceBuildContext c,
    ReferenceRecipe r,
  ) {
    final base = c.references[r.sourceIds.first]?.geometry;
    if (base is! PlaneGeometry) throw StateError('Plane source required');
    final direction = base.normal.cross(const Vec3(1, 0, 0)).length > 0
        ? base.normal.cross(const Vec3(1, 0, 0)).normalized
        : base.normal.cross(const Vec3(0, 1, 0)).normalized;
    return ReferenceBuildResult(
      PlaneGeometry(base.origin, direction),
      const ReferenceAnalytics(
        precision: 1,
        rmsError: 0,
        maxDeviation: 0,
        confidence: 1,
        fitQuality: 1,
        areaUsed: 0,
        coverage: 1,
        pointCount: 1,
      ),
      r.sourceIds.first,
    );
  }

  ReferenceBuildResult _mid(ReferenceBuildContext c, ReferenceRecipe r) {
    final a = c.references[r.sourceIds[0]]?.geometry,
        b = c.references[r.sourceIds[1]]?.geometry;
    if (a is! PlaneGeometry || b is! PlaneGeometry) {
      throw StateError('Two planes required');
    }
    return ReferenceBuildResult(
      PlaneGeometry(
        (a.origin + b.origin) / 2,
        (a.normal + b.normal).normalized,
      ),
      const ReferenceAnalytics(
        precision: 1,
        rmsError: 0,
        maxDeviation: 0,
        confidence: 1,
        fitQuality: 1,
        areaUsed: 0,
        coverage: 1,
        pointCount: 2,
      ),
      r.sourceIds.join(':'),
    );
  }
}
