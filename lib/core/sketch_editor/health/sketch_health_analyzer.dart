import 'dart:math' as math;

import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/models/sketch_models.dart';

enum SketchHealthIssueType {
  gap,
  duplicate,
  overlap,
  selfIntersection,
  tinyGeometry,
  openEnd,
}

class SketchHealthIssue {
  const SketchHealthIssue({
    required this.type,
    required this.message,
    required this.entityIds,
    required this.locations,
    this.distance,
    this.endpointReferences = const [],
    this.canAutoHeal = false,
  });
  final SketchHealthIssueType type;
  final String message;
  final List<String> entityIds;
  final List<SketchVector> locations;
  final double? distance;
  final List<String> endpointReferences;
  final bool canAutoHeal;
}

class SketchHealthReport {
  const SketchHealthReport({required this.issues, required this.closedProfile});
  final List<SketchHealthIssue> issues;
  final bool closedProfile;
  Iterable<SketchHealthIssue> ofType(SketchHealthIssueType type) =>
      issues.where((issue) => issue.type == type);
  bool get hasGaps => ofType(SketchHealthIssueType.gap).isNotEmpty;
  bool get hasDuplicates => issues.any(
    (issue) =>
        issue.type == SketchHealthIssueType.duplicate ||
        issue.type == SketchHealthIssueType.overlap,
  );
  bool get hasSelfIntersections =>
      ofType(SketchHealthIssueType.selfIntersection).isNotEmpty;
  bool get hasTinyGeometry =>
      ofType(SketchHealthIssueType.tinyGeometry).isNotEmpty;
  bool get hasOpenEnds => ofType(SketchHealthIssueType.openEnd).isNotEmpty;
  bool get readyForSurface =>
      closedProfile &&
      !hasGaps &&
      !hasDuplicates &&
      !hasSelfIntersections &&
      !hasTinyGeometry &&
      !hasOpenEnds;
}

class SketchHealthAnalyzer {
  const SketchHealthAnalyzer({
    this.connectionTolerance = 1e-4,
    this.gapTolerance = .1,
    this.tinyThreshold = .01,
  });
  final double connectionTolerance, gapTolerance, tinyThreshold;

  SketchHealthReport analyze(Iterable<SketchEntity> source) {
    final entities = source
        .where((entity) => entity.visible && !entity.construction)
        .toList(growable: false);
    final issues = <SketchHealthIssue>[];
    final endpoints = <_Endpoint>[];
    final signatures = <String, String>{};
    for (final entity in entities) {
      endpoints.addAll(_endpoints(entity));
      final measure = _measure(entity);
      if (measure != null && measure < tinyThreshold) {
        issues.add(
          SketchHealthIssue(
            type: SketchHealthIssueType.tinyGeometry,
            message:
                'Tiny ${entity.type.name}: ${measure.toStringAsFixed(6)} mm',
            entityIds: [entity.id],
            locations: _endpoints(entity).map((item) => item.point).toList(),
          ),
        );
      }
      final signature = _signature(entity);
      if (signature != null) {
        final prior = signatures[signature];
        if (prior == null) {
          signatures[signature] = entity.id;
        } else {
          issues.add(
            SketchHealthIssue(
              type: SketchHealthIssueType.duplicate,
              message: 'Duplicate geometry',
              entityIds: [prior, entity.id],
              locations: _sample(entity),
            ),
          );
        }
      }
    }

    final matched = <int>{};
    for (var i = 0; i < endpoints.length; i++) {
      for (var j = i + 1; j < endpoints.length; j++) {
        if (endpoints[i].entityId == endpoints[j].entityId) continue;
        if (_distance(endpoints[i].point, endpoints[j].point) <=
            connectionTolerance) {
          matched
            ..add(i)
            ..add(j);
        }
      }
    }
    final loose = [
      for (var i = 0; i < endpoints.length; i++)
        if (!matched.contains(i)) i,
    ];
    final gapEndpoints = <int>{};
    for (var a = 0; a < loose.length; a++) {
      for (var b = a + 1; b < loose.length; b++) {
        final first = endpoints[loose[a]], second = endpoints[loose[b]];
        if (first.entityId == second.entityId) continue;
        final distance = _distance(first.point, second.point);
        if (distance > connectionTolerance && distance <= gapTolerance) {
          gapEndpoints
            ..add(loose[a])
            ..add(loose[b]);
          issues.add(
            SketchHealthIssue(
              type: SketchHealthIssueType.gap,
              message: 'Gap ${distance.toStringAsFixed(3)} mm',
              entityIds: [first.entityId, second.entityId],
              locations: [first.point, second.point],
              distance: distance,
              endpointReferences: [first.reference, second.reference],
              canAutoHeal: true,
            ),
          );
        }
      }
    }
    for (final index in loose.where((index) => !gapEndpoints.contains(index))) {
      final endpoint = endpoints[index];
      issues.add(
        SketchHealthIssue(
          type: SketchHealthIssueType.openEnd,
          message: 'Open endpoint',
          entityIds: [endpoint.entityId],
          locations: [endpoint.point],
          endpointReferences: [endpoint.reference],
        ),
      );
    }

    for (var i = 0; i < entities.length; i++) {
      for (var j = i + 1; j < entities.length; j++) {
        if (_isDuplicatePair(issues, entities[i].id, entities[j].id)) continue;
        final intersection = _interiorIntersection(entities[i], entities[j]);
        if (intersection != null) {
          issues.add(
            SketchHealthIssue(
              type: SketchHealthIssueType.selfIntersection,
              message: 'Profile entities cross',
              entityIds: [entities[i].id, entities[j].id],
              locations: [intersection],
            ),
          );
        } else if (_overlap(entities[i], entities[j])) {
          issues.add(
            SketchHealthIssue(
              type: SketchHealthIssueType.overlap,
              message: 'Overlapping geometry',
              entityIds: [entities[i].id, entities[j].id],
              locations: [..._sample(entities[i]), ..._sample(entities[j])],
            ),
          );
        }
      }
    }
    final hasOpenTopology = issues.any(
      (issue) =>
          issue.type == SketchHealthIssueType.openEnd ||
          issue.type == SketchHealthIssueType.gap,
    );
    final hasClosedEntity = entities.any((entity) => entity is SketchCircle);
    final hasChainedGeometry = endpoints.isNotEmpty && !hasOpenTopology;
    return SketchHealthReport(
      issues: List.unmodifiable(issues),
      closedProfile:
          entities.isNotEmpty && (hasClosedEntity || hasChainedGeometry),
    );
  }

  List<_Endpoint> _endpoints(SketchEntity entity) {
    if (entity is SketchLine) {
      return [
        _Endpoint(
          entity.id,
          '${entity.id}:start',
          SketchVector.fromJson(entity.parameters['start']),
        ),
        _Endpoint(
          entity.id,
          '${entity.id}:end',
          SketchVector.fromJson(entity.parameters['end']),
        ),
      ];
    }
    if (entity is SketchArc) {
      final c = SketchVector.fromJson(entity.parameters['center']);
      final r = (entity.parameters['radius'] as num).toDouble();
      final a = (entity.parameters['startAngle'] as num).toDouble();
      final b = (entity.parameters['endAngle'] as num).toDouble();
      return [
        _Endpoint(
          entity.id,
          '${entity.id}:start',
          SketchVector(c.x + r * math.cos(a), c.y + r * math.sin(a)),
        ),
        _Endpoint(
          entity.id,
          '${entity.id}:end',
          SketchVector(c.x + r * math.cos(b), c.y + r * math.sin(b)),
        ),
      ];
    }
    return const [];
  }

  double? _measure(SketchEntity entity) {
    if (entity is SketchLine) {
      return _distance(
        SketchVector.fromJson(entity.parameters['start']),
        SketchVector.fromJson(entity.parameters['end']),
      );
    }
    if (entity is SketchArc) {
      final radius = (entity.parameters['radius'] as num).toDouble();
      final sweep =
          ((entity.parameters['endAngle'] as num).toDouble() -
                  (entity.parameters['startAngle'] as num).toDouble())
              .abs();
      return radius * sweep;
    }
    if (entity is SketchCircle) {
      return (entity.parameters['radius'] as num).toDouble() * math.pi * 2;
    }
    return null;
  }

  String? _signature(SketchEntity entity) {
    String point(SketchVector p) =>
        '${(p.x / connectionTolerance).round()},${(p.y / connectionTolerance).round()}';
    if (entity is SketchLine) {
      final keys = [
        point(SketchVector.fromJson(entity.parameters['start'])),
        point(SketchVector.fromJson(entity.parameters['end'])),
      ]..sort();
      return 'line:${keys.join('|')}';
    }
    if (entity is SketchCircle) {
      return 'circle:${point(SketchVector.fromJson(entity.parameters['center']))}:${((entity.parameters['radius'] as num).toDouble() / connectionTolerance).round()}';
    }
    if (entity is SketchArc) {
      final ends = _endpoints(entity).map((item) => point(item.point)).toList()
        ..sort();
      return 'arc:${point(SketchVector.fromJson(entity.parameters['center']))}:${((entity.parameters['radius'] as num).toDouble() / connectionTolerance).round()}:${ends.join('|')}';
    }
    return null;
  }

  List<SketchVector> _sample(SketchEntity entity) {
    if (entity is SketchLine) {
      return _endpoints(entity).map((e) => e.point).toList();
    }
    if (entity is SketchCircle || entity is SketchArc) {
      final center = SketchVector.fromJson(entity.parameters['center']);
      final radius = (entity.parameters['radius'] as num).toDouble();
      final start = entity is SketchArc
          ? (entity.parameters['startAngle'] as num).toDouble()
          : 0.0;
      final end = entity is SketchArc
          ? (entity.parameters['endAngle'] as num).toDouble()
          : math.pi * 2;
      return [
        for (var i = 0; i <= 48; i++)
          SketchVector(
            center.x + radius * math.cos(start + (end - start) * i / 48),
            center.y + radius * math.sin(start + (end - start) * i / 48),
          ),
      ];
    }
    return const [];
  }

  SketchVector? _interiorIntersection(SketchEntity first, SketchEntity second) {
    final a = _sample(first), b = _sample(second);
    for (var i = 1; i < a.length; i++) {
      for (var j = 1; j < b.length; j++) {
        final hit = _segmentIntersection(a[i - 1], a[i], b[j - 1], b[j]);
        if (hit != null && !_isSharedEndpoint(hit, first, second)) return hit;
      }
    }
    return null;
  }

  SketchVector? _segmentIntersection(
    SketchVector a,
    SketchVector b,
    SketchVector c,
    SketchVector d,
  ) {
    final rx = b.x - a.x, ry = b.y - a.y, sx = d.x - c.x, sy = d.y - c.y;
    final denominator = rx * sy - ry * sx;
    if (denominator.abs() <= 1e-12) return null;
    final t = ((c.x - a.x) * sy - (c.y - a.y) * sx) / denominator;
    final u = ((c.x - a.x) * ry - (c.y - a.y) * rx) / denominator;
    if (t <= 1e-7 || t >= 1 - 1e-7 || u <= 1e-7 || u >= 1 - 1e-7) return null;
    return SketchVector(a.x + rx * t, a.y + ry * t);
  }

  bool _isSharedEndpoint(SketchVector point, SketchEntity a, SketchEntity b) =>
      _endpoints(
        a,
      ).any((e) => _distance(e.point, point) <= connectionTolerance) &&
      _endpoints(
        b,
      ).any((e) => _distance(e.point, point) <= connectionTolerance);

  bool _overlap(SketchEntity a, SketchEntity b) {
    if (a is! SketchLine || b is! SketchLine) return false;
    final a0 = SketchVector.fromJson(a.parameters['start']),
        a1 = SketchVector.fromJson(a.parameters['end']);
    final b0 = SketchVector.fromJson(b.parameters['start']),
        b1 = SketchVector.fromJson(b.parameters['end']);
    final cross1 =
        (a1.x - a0.x) * (b0.y - a0.y) - (a1.y - a0.y) * (b0.x - a0.x);
    final cross2 =
        (a1.x - a0.x) * (b1.y - a0.y) - (a1.y - a0.y) * (b1.x - a0.x);
    if (cross1.abs() > connectionTolerance ||
        cross2.abs() > connectionTolerance) {
      return false;
    }
    final useX = (a1.x - a0.x).abs() >= (a1.y - a0.y).abs();
    final aa = [useX ? a0.x : a0.y, useX ? a1.x : a1.y]..sort();
    final bb = [useX ? b0.x : b0.y, useX ? b1.x : b1.y]..sort();
    return math.min(aa[1], bb[1]) - math.max(aa[0], bb[0]) >
        connectionTolerance;
  }

  bool _isDuplicatePair(List<SketchHealthIssue> issues, String a, String b) =>
      issues.any(
        (issue) =>
            issue.type == SketchHealthIssueType.duplicate &&
            issue.entityIds.contains(a) &&
            issue.entityIds.contains(b),
      );

  double _distance(SketchVector a, SketchVector b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}

class _Endpoint {
  const _Endpoint(this.entityId, this.reference, this.point);
  final String entityId, reference;
  final SketchVector point;
}
