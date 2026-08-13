import 'dart:math' as math;

import '../../smart_regions/models/geometry.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch.dart';

class SketchAnalyticsEngine {
  const SketchAnalyticsEngine();
  SketchAnalytics evaluate(List<SketchEntity> entities) {
    var length = 0.0, area = 0.0, curvature = 0.0, segments = 0, degree = 1;
    var closed = entities.isNotEmpty;
    for (final entity in entities) {
      final points = entity.anchors.map((anchor) => anchor.position).toList();
      for (var index = 1; index < points.length; index++) {
        length += (points[index] - points[index - 1]).length;
        segments++;
      }
      if (entity.kind == SketchEntityKind.circle) {
        final radius = entity.parameters['radius'] ?? 0;
        length += 2 * math.pi * radius;
        area += math.pi * radius * radius;
      } else if (entity.kind == SketchEntityKind.rectangle &&
          points.length >= 2) {
        final delta = points[1] - points[0];
        area += delta.x.abs() * delta.y.abs();
      } else if (_isClosed(entity, points)) {
        area += _polygonArea(points);
      } else {
        closed = false;
      }
      degree = math.max(degree, (entity.parameters['degree'] ?? 1).round());
      curvature += entity.parameters['curvature'] ?? 0;
    }
    final continuity = _continuity(entities);
    return SketchAnalytics(
      length: length,
      area: area,
      averageCurvature: entities.isEmpty ? 0 : curvature / entities.length,
      continuity: continuity,
      tangency: continuity,
      closed: closed,
      quality: (continuity * .6 + (entities.isEmpty ? 0 : .4)).clamp(0, 1),
      degree: degree,
      segmentCount: segments,
    );
  }

  bool _isClosed(SketchEntity entity, List<Vec3> points) =>
      entity.kind == SketchEntityKind.circle ||
      entity.kind == SketchEntityKind.ellipse ||
      entity.kind == SketchEntityKind.rectangle ||
      (points.length > 2 && (points.first - points.last).length <= 1e-6);

  double _polygonArea(List<Vec3> points) {
    var value = 0.0;
    for (var i = 0; i < points.length; i++) {
      final next = points[(i + 1) % points.length];
      value += points[i].x * next.y - next.x * points[i].y;
    }
    return value.abs() / 2;
  }

  double _continuity(List<SketchEntity> entities) {
    if (entities.length < 2) return entities.isEmpty ? 0 : 1;
    var matches = 0;
    for (var i = 1; i < entities.length; i++) {
      if (entities[i - 1].anchors.isNotEmpty &&
          entities[i].anchors.isNotEmpty &&
          (entities[i - 1].anchors.last.position -
                      entities[i].anchors.first.position)
                  .length <=
              1e-6) {
        matches++;
      }
    }
    return matches / (entities.length - 1);
  }
}
