import '../../smart_regions/models/geometry.dart';
import 'reference_builder.dart';
import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

const _exact = ReferenceAnalytics(
  precision: 1,
  rmsError: 0,
  maxDeviation: 0,
  confidence: 1,
  fitQuality: 1,
  areaUsed: 0,
  coverage: 1,
  pointCount: 2,
);

class AxisBuilder implements ReferenceBuilder {
  @override
  String get id => 'axis';
  @override
  Future<ReferenceBuildResult> build(
    ReferenceBuildContext c,
    ReferenceRecipe r,
  ) async {
    final method = r.parameters['method'] as String? ?? 'twoPoints';
    if (method == 'twoPoints') {
      final p = (r.parameters['points'] as List)
          .map((e) => Vec3.fromJson(e as List))
          .toList();
      return ReferenceBuildResult(
        AxisGeometry(p[0], (p[1] - p[0]).normalized),
        _exact,
        p.toString(),
      );
    }
    if (method == 'normal') {
      final plane = c.references[r.sourceIds.first]?.geometry;
      if (plane is! PlaneGeometry) throw StateError('Plane required');
      return ReferenceBuildResult(
        AxisGeometry(plane.origin, plane.normal),
        _exact,
        r.sourceIds.first,
      );
    }
    if (method == 'planeIntersection') {
      final a = c.references[r.sourceIds[0]]?.geometry,
          b = c.references[r.sourceIds[1]]?.geometry;
      if (a is! PlaneGeometry || b is! PlaneGeometry) {
        throw StateError('Two planes required');
      }
      final direction = a.normal.cross(b.normal).normalized;
      if (direction.length == 0) throw StateError('Parallel planes');
      return ReferenceBuildResult(
        AxisGeometry((a.origin + b.origin) / 2, direction),
        _exact,
        r.sourceIds.join(':'),
      );
    }
    throw UnsupportedError('Axis method $method');
  }
}

class PointBuilder implements ReferenceBuilder {
  @override
  String get id => 'point';
  @override
  Future<ReferenceBuildResult> build(
    ReferenceBuildContext c,
    ReferenceRecipe r,
  ) async {
    final method = r.parameters['method'] as String? ?? 'explicit';
    Vec3 point;
    if (method == 'centroid') {
      final region = c.regions[r.sourceIds.first];
      if (region == null) throw StateError('Region required');
      point = region.statistics.centroid;
    } else if (method == 'onAxis') {
      final axis = c.references[r.sourceIds.first]?.geometry;
      if (axis is! AxisGeometry) throw StateError('Axis required');
      final distance = (r.parameters['distance'] as num? ?? 0).toDouble();
      point =
          axis.origin +
          Vec3(
            axis.direction.x * distance,
            axis.direction.y * distance,
            axis.direction.z * distance,
          );
    } else {
      point = Vec3.fromJson(r.parameters['point'] as List);
    }
    return ReferenceBuildResult(
      PointGeometry(point),
      _exact,
      r.sourceIds.join(':'),
    );
  }
}

class CurveBuilder implements ReferenceBuilder {
  @override
  String get id => 'curve';
  @override
  Future<ReferenceBuildResult> build(
    ReferenceBuildContext c,
    ReferenceRecipe r,
  ) async {
    final method = r.parameters['method'] as String? ?? 'explicit';
    late final List<Vec3> points;
    if (method == 'region' || method == 'edge') {
      final region = c.regions[r.sourceIds.first];
      if (region == null) throw StateError('Region required');
      final mesh = c.meshes[region.meshId];
      if (mesh == null) throw StateError('Mesh required');
      final selected = region.selection.indices.toSet(), boundary = <int>{};
      for (final index in selected) {
        final triangle = mesh.triangles[index];
        if (mesh.triangleNeighbors[index].any((n) => !selected.contains(n)) ||
            mesh.triangleNeighbors[index].length < 3) {
          boundary.addAll([triangle.a, triangle.b, triangle.c]);
        }
      }
      points = boundary.map((i) => mesh.vertices[i]).toList();
    } else {
      points = (r.parameters['points'] as List)
          .map((e) => Vec3.fromJson(e as List))
          .toList();
    }
    if (points.length < 2) {
      throw ArgumentError('Curve requires at least 2 points');
    }
    return ReferenceBuildResult(
      CurveGeometry(
        points,
        closed: r.parameters['closed'] as bool? ?? method == 'region',
      ),
      _exact,
      points.toString(),
    );
  }
}

class CoordinateSystemBuilder implements ReferenceBuilder {
  @override
  String get id => 'coordinateSystem';
  @override
  Future<ReferenceBuildResult> build(
    ReferenceBuildContext c,
    ReferenceRecipe r,
  ) async {
    final origin = Vec3.fromJson(
          (r.parameters['origin'] as List?) ?? [0, 0, 0],
        ),
        x = Vec3.fromJson(
          (r.parameters['xAxis'] as List?) ?? [1, 0, 0],
        ).normalized,
        y = Vec3.fromJson(
          (r.parameters['yAxis'] as List?) ?? [0, 1, 0],
        ).normalized,
        z = x.cross(y).normalized;
    return ReferenceBuildResult(
      CoordinateSystemGeometry(origin, x, y, z),
      _exact,
      r.parameters.toString(),
    );
  }
}
