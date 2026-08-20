import 'dart:math' as math;

import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../snapping/editor_snapping.dart';

enum SketchInferenceType {
  horizontal,
  vertical,
  endpoint,
  midpoint,
  center,
  parallel,
  perpendicular,
  tangent,
}

extension SketchInferenceVisual on SketchInferenceType {
  String get glyph => switch (this) {
    SketchInferenceType.horizontal => 'H',
    SketchInferenceType.vertical => 'V',
    SketchInferenceType.endpoint => '●',
    SketchInferenceType.midpoint => '⊙',
    SketchInferenceType.center => '○',
    SketchInferenceType.parallel => '//',
    SketchInferenceType.perpendicular => '⊥',
    SketchInferenceType.tangent => 'T',
  };
}

class SketchInference {
  const SketchInference({
    required this.type,
    required this.position,
    required this.score,
    this.referenceEntityId,
  });
  final SketchInferenceType type;
  final SketchVector position;
  final double score;
  final String? referenceEntityId;
}

/// Suggests one probable geometric intention. Results are transient and never
/// create constraints or mutate Sketch entities.
class SketchInferenceEngine {
  const SketchInferenceEngine({this.angularToleranceDegrees = 4});
  final double angularToleranceDegrees;

  SketchInference? inferLine({
    required SketchVector cursor,
    required SketchVector? start,
    required Iterable<SketchEntity> entities,
    SnapCandidate? snap,
    double spatialTolerance = .5,
  }) {
    final snapInference = _fromSnap(snap);
    if (snapInference != null) return snapInference;
    if (start == null) return null;
    final dx = cursor.x - start.x, dy = cursor.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 1e-9) return null;
    final angle = math.atan2(dy, dx);
    final candidates = <SketchInference>[];
    void directionCandidate(
      SketchInferenceType type,
      double targetAngle,
      int priority, {
      String? referenceId,
    }) {
      final deviation = _undirectedAngleDistance(angle, targetAngle);
      final tolerance = angularToleranceDegrees * math.pi / 180;
      if (deviation > tolerance) return;
      // Parallel/perpendicular axes are undirected, but the preview is not:
      // it must remain on the same side of the anchor as the pointer. Pick
      // the equivalent axis direction whose dot product with the cursor
      // vector is positive instead of always rebuilding toward +X/+Y.
      final alignedAngle = math.cos(angle - targetAngle) < 0
          ? targetAngle + math.pi
          : targetAngle;
      candidates.add(
        SketchInference(
          type: type,
          position: SketchVector(
            start.x + length * math.cos(alignedAngle),
            start.y + length * math.sin(alignedAngle),
          ),
          score: priority + (1 - deviation / tolerance),
          referenceEntityId: referenceId,
        ),
      );
    }

    directionCandidate(SketchInferenceType.horizontal, 0, 40);
    directionCandidate(SketchInferenceType.vertical, math.pi / 2, 40);
    for (final entity in entities) {
      if (entity is SketchLine) {
        final a = SketchVector.fromJson(entity.parameters['start']);
        final b = SketchVector.fromJson(entity.parameters['end']);
        final referenceAngle = math.atan2(b.y - a.y, b.x - a.x);
        directionCandidate(
          SketchInferenceType.parallel,
          referenceAngle,
          50,
          referenceId: entity.id,
        );
        directionCandidate(
          SketchInferenceType.perpendicular,
          referenceAngle + math.pi / 2,
          60,
          referenceId: entity.id,
        );
      }
      if (entity is SketchCircle || entity is SketchArc) {
        final center = SketchVector.fromJson(entity.parameters['center']);
        final radius = (entity.parameters['radius'] as num).toDouble();
        final tangent = _nearestTangent(start, cursor, center, radius);
        if (tangent != null && _distance(cursor, tangent) <= spatialTolerance) {
          candidates.add(
            SketchInference(
              type: SketchInferenceType.tangent,
              position: tangent,
              score: 70 + (1 - _distance(cursor, tangent) / spatialTolerance),
              referenceEntityId: entity.id,
            ),
          );
        }
      }
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.firstOrNull;
  }

  SketchInference? _fromSnap(SnapCandidate? snap) {
    if (snap == null) return null;
    final type = switch (snap.type) {
      EditorSnapType.endpoint => SketchInferenceType.endpoint,
      EditorSnapType.midpoint => SketchInferenceType.midpoint,
      EditorSnapType.center => SketchInferenceType.center,
      _ => null,
    };
    return type == null
        ? null
        : SketchInference(
            type: type,
            position: snap.position,
            score: switch (type) {
              SketchInferenceType.endpoint => 100,
              SketchInferenceType.midpoint => 90,
              SketchInferenceType.center => 80,
              _ => 0,
            },
            referenceEntityId: snap.entityId,
          );
  }

  SketchVector? _nearestTangent(
    SketchVector point,
    SketchVector cursor,
    SketchVector center,
    double radius,
  ) {
    final dx = point.x - center.x, dy = point.y - center.y;
    final distance2 = dx * dx + dy * dy;
    if (distance2 <= radius * radius + 1e-12) return null;
    final base = math.atan2(dy, dx);
    final offset = math.acos(radius / math.sqrt(distance2));
    final first = SketchVector(
      center.x + radius * math.cos(base + offset),
      center.y + radius * math.sin(base + offset),
    );
    final second = SketchVector(
      center.x + radius * math.cos(base - offset),
      center.y + radius * math.sin(base - offset),
    );
    return _distance(cursor, first) <= _distance(cursor, second)
        ? first
        : second;
  }

  double _undirectedAngleDistance(double a, double b) {
    var value = (a - b).abs() % math.pi;
    if (value > math.pi / 2) value = math.pi - value;
    return value.abs();
  }

  double _distance(SketchVector a, SketchVector b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}
