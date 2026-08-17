import 'dart:math' as math;

import '../builders/sketch_builders.dart';
import '../engine/sketch_engine.dart';
import '../entities/sketch_entities.dart';
import '../history/sketch_history.dart';
import '../models/sketch_models.dart';

class SketchEngineApi {
  SketchEngineApi(this.engine) : builders = SketchBuilders(engine);
  final SketchEngine engine;
  final SketchBuilders builders;
  Sketch createSketch(
    String name, {
    SketchPlane? plane,
    SketchCoordinateSystem? coordinates,
  }) => engine.createSketch(name, plane: plane, coordinates: coordinates);
  void deleteSketch(String id) => engine.deleteSketch(id);
  void openSketch(String id) => engine.openSketch(id);
  void closeSketch() => engine.closeSketch();
  void deleteEntity(String id) => engine.deleteEntity(id);
  void move(String id, SketchVector delta) => engine.modify(
    id,
    SketchHistoryAction.move,
    (entity) => _transformPoints(entity, (point) => point + delta),
  );
  void rotate(
    String id,
    double angle, {
    SketchVector center = const SketchVector(0, 0),
  }) => engine.modify(id, SketchHistoryAction.rotate, (entity) {
    final cosine = math.cos(angle), sine = math.sin(angle);
    _transformPoints(entity, (point) {
      final x = point.x - center.x, y = point.y - center.y;
      return SketchVector(
        center.x + x * cosine - y * sine,
        center.y + x * sine + y * cosine,
      );
    });
    if (entity is SketchArc) {
      entity.parameters['startAngle'] =
          (entity.parameters['startAngle'] as num).toDouble() + angle;
      entity.parameters['endAngle'] =
          (entity.parameters['endAngle'] as num).toDouble() + angle;
    }
  });
  void scale(
    String id,
    double factor, {
    double? factorY,
    SketchVector center = const SketchVector(0, 0),
  }) => engine.modify(id, SketchHistoryAction.scale, (entity) {
    final sy = factorY ?? factor;
    _transformPoints(
      entity,
      (point) => SketchVector(
        center.x + (point.x - center.x) * factor,
        center.y + (point.y - center.y) * sy,
      ),
    );
    if (entity is SketchCircle || entity is SketchArc) {
      if ((factor - sy).abs() > 1e-12) {
        throw ArgumentError('Non-uniform scale is invalid for circles/arcs.');
      }
      entity.parameters['radius'] =
          (entity.parameters['radius'] as num).toDouble() * factor.abs();
    } else if (entity is SketchEllipse) {
      entity.parameters['radiusX'] =
          (entity.parameters['radiusX'] as num).toDouble() * factor.abs();
      entity.parameters['radiusY'] =
          (entity.parameters['radiusY'] as num).toDouble() * sy.abs();
    }
  });
  void mirror(
    String id, {
    SketchVector axisStart = const SketchVector(0, 0),
    SketchVector axisEnd = const SketchVector(1, 0),
  }) => engine.modify(id, SketchHistoryAction.mirror, (entity) {
    final dx = axisEnd.x - axisStart.x, dy = axisEnd.y - axisStart.y;
    final length2 = dx * dx + dy * dy;
    if (length2 <= 1e-24) throw ArgumentError('Mirror axis is degenerate.');
    _transformPoints(entity, (point) {
      final t =
          ((point.x - axisStart.x) * dx + (point.y - axisStart.y) * dy) /
          length2;
      final projection = SketchVector(
        axisStart.x + t * dx,
        axisStart.y + t * dy,
      );
      return SketchVector(
        2 * projection.x - point.x,
        2 * projection.y - point.y,
      );
    });
    if (entity is SketchArc) {
      final start = (entity.parameters['startAngle'] as num).toDouble();
      final end = (entity.parameters['endAngle'] as num).toDouble();
      final axisAngle = math.atan2(dy, dx);
      entity.parameters['startAngle'] = 2 * axisAngle - end;
      entity.parameters['endAngle'] = 2 * axisAngle - start;
    }
  });
  void setConstruction(String id, bool value) => engine.modify(
    id,
    SketchHistoryAction.construction,
    (e) => e.construction = value,
  );
  void setReference(String id, bool value) => engine.modify(
    id,
    SketchHistoryAction.reference,
    (e) => e.reference = value,
  );
  List<Sketch> get sketches => List.unmodifiable(engine.sketches.values);
  SketchEntity? entity(String id) => engine.entities[id];
  Future<void> load() => engine.load();
  Future<void> persist() => engine.persist();

  static void _transformPoints(
    SketchEntity entity,
    SketchVector Function(SketchVector) transform,
  ) {
    void point(String key) {
      final value = entity.parameters[key];
      if (value != null) {
        entity.parameters[key] = transform(
          SketchVector.fromJson(value),
        ).toJson();
      }
    }

    switch (entity) {
      case SketchPoint():
        point('point');
      case SketchLine():
        point('start');
        point('end');
      case SketchCircle() || SketchArc() || SketchEllipse():
        point('center');
      case SketchSpline():
        for (final key in ['points', 'sampledPoints']) {
          final values = entity.parameters[key];
          if (values is List) {
            entity.parameters[key] = values
                .map(
                  (value) => transform(SketchVector.fromJson(value)).toJson(),
                )
                .toList();
          }
        }
      default:
        break;
    }
  }
}
