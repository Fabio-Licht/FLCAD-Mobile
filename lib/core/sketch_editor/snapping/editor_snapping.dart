import 'dart:math' as math;
import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../analytics/editor_analytics.dart';

enum EditorSnapType {
  endpoint,
  midpoint,
  center,
  intersection,
  quadrant,
  perpendicular,
  parallel,
  tangent,
  nearest,
  origin,
  grid,
  reference,
  projection,
}

class EditorSnapSettings {
  EditorSnapSettings({
    Set<EditorSnapType>? enabled,
    this.tolerance = 8,
    Map<EditorSnapType, int>? priority,
  }) : enabled = enabled ?? EditorSnapType.values.toSet(),
       priority = priority ?? <EditorSnapType, int>{};
  final Set<EditorSnapType> enabled;
  double tolerance;
  final Map<EditorSnapType, int> priority;
}

class SnapCandidate {
  const SnapCandidate(
    this.type,
    this.position,
    this.distance, {
    this.entityId,
    this.diagnostics = const [],
  });
  final EditorSnapType type;
  final SketchVector position;
  final double distance;
  final String? entityId;
  final List<String> diagnostics;
}

class EditorSnappingEngine {
  EditorSnappingEngine(this.analytics, {EditorSnapSettings? settings})
    : settings = settings ?? EditorSnapSettings();
  final EditorAnalytics analytics;
  final EditorSnapSettings settings;
  SnapCandidate? preview;
  SnapCandidate? snap(SketchVector cursor, Iterable<SketchEntity> entities) {
    final candidates = <SnapCandidate>[
      if (settings.enabled.contains(EditorSnapType.origin))
        SnapCandidate(
          EditorSnapType.origin,
          const SketchVector(0, 0),
          _distance(cursor, const SketchVector(0, 0)),
        ),
    ];
    for (final e in entities) {
      candidates.addAll(_entityCandidates(cursor, e));
    }
    candidates.removeWhere(
      (c) =>
          c.distance > settings.tolerance || !settings.enabled.contains(c.type),
    );
    candidates.sort((a, b) {
      final p = (settings.priority[b.type] ?? 0).compareTo(
        settings.priority[a.type] ?? 0,
      );
      return p != 0 ? p : a.distance.compareTo(b.distance);
    });
    preview = candidates.firstOrNull;
    analytics.snapCount++;
    return preview;
  }

  List<SnapCandidate> _entityCandidates(SketchVector cursor, SketchEntity e) {
    final result = <SnapCandidate>[];
    if (e is SketchPoint) {
      final p = SketchVector.fromJson(e.parameters['point']);
      result.add(
        SnapCandidate(
          EditorSnapType.endpoint,
          p,
          _distance(cursor, p),
          entityId: e.id,
        ),
      );
    }
    if (e is SketchLine) {
      final a = SketchVector.fromJson(e.parameters['start']),
          b = SketchVector.fromJson(e.parameters['end']),
          m = SketchVector((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2);
      result
        ..add(
          SnapCandidate(
            EditorSnapType.endpoint,
            a,
            _distance(cursor, a),
            entityId: e.id,
          ),
        )
        ..add(
          SnapCandidate(
            EditorSnapType.endpoint,
            b,
            _distance(cursor, b),
            entityId: e.id,
          ),
        )
        ..add(
          SnapCandidate(
            EditorSnapType.midpoint,
            m,
            _distance(cursor, m),
            entityId: e.id,
          ),
        );
    }
    if (e is SketchCircle || e is SketchArc || e is SketchEllipse) {
      final p = SketchVector.fromJson(e.parameters['center']);
      result.add(
        SnapCandidate(
          EditorSnapType.center,
          p,
          _distance(cursor, p),
          entityId: e.id,
        ),
      );
    }
    if (e.reference) {
      final p = e.parameters['point'];
      if (p is List) {
        final v = SketchVector.fromJson(p);
        result.add(
          SnapCandidate(
            EditorSnapType.reference,
            v,
            _distance(cursor, v),
            entityId: e.id,
          ),
        );
      }
    }
    return result;
  }

  double _distance(SketchVector a, SketchVector b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}
