import 'dart:math' as math;
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/history/sketch_history.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../analytics/editor_analytics.dart';
import '../analytics/sketch_quality.dart';
import '../editing/degrees_of_freedom.dart';
import '../graph/editor_graph.dart';
import '../history/editor_history.dart';
import '../integration/sketch_advisor.dart';
import '../models/editor_models.dart';
import '../preview/preview_engine.dart';
import '../repository/editor_repository.dart';
import '../runtime/editor_runtime.dart';
import '../selection/editor_selection.dart';
import '../snapping/editor_snapping.dart';
import '../toolbar/sketch_toolbar.dart';

class SketchEditorEngine {
  SketchEditorEngine({
    required this.sketch,
    required this.constraints,
    required this.repository,
    EditorRuntime? runtime,
    EditorAnalytics? analytics,
    EditorHistory? history,
  }) : runtime = runtime ?? EditorRuntime(),
       analytics = analytics ?? EditorAnalytics(),
       history = history ?? EditorHistory() {
    selection = EditorSelectionEngine(this.analytics);
    snapping = EditorSnappingEngine(this.analytics);
    preview = PreviewEngine(this.analytics);
  }
  final SketchEngineApi sketch;
  final ConstraintApi constraints;
  final EditorRepository repository;
  final EditorRuntime runtime;
  final EditorAnalytics analytics;
  final EditorHistory history;
  final graph = EditorGraph();
  final toolbar = SketchToolbar();
  late final EditorSelectionEngine selection;
  late final EditorSnappingEngine snapping;
  late final PreviewEngine preview;
  final _undoCounts = <int>[], _redoCounts = <int>[];

  EditorOperation start(
    SketchToolType tool,
    List<SketchVector> points, {
    Map<String, dynamic>? parameters,
  }) {
    toolbar.activate(tool);
    final op = EditorOperation(tool, points: points, parameters: parameters);
    history.record(EditorHistoryAction.preview, op.id);
    return preview.begin(op);
  }

  List<SketchEntity> confirm(String previewId) {
    final watch = Stopwatch()..start();
    final operation = preview.confirm(previewId);
    final created = <SketchEntity>[];
    try {
      sketch.engine.transaction(
        'editor:${operation.id}',
        () => _create(operation, created),
      );
      graph.record(operation.id, created.map((e) => e.id));
      _undoCounts.add(created.length);
      _redoCounts.clear();
      history.record(EditorHistoryAction.commit, operation.id);
      analytics.editCount++;
      analytics.entities = sketch.engine.entities.length;
      return created;
    } catch (_) {
      operation.status = EditorOperationStatus.failed;
      history.record(EditorHistoryAction.rollback, operation.id);
      rethrow;
    } finally {
      watch.stop();
      analytics.totalEditMicros += watch.elapsedMicroseconds;
    }
  }

  void cancel(String id) {
    preview.cancel(id);
    history.record(EditorHistoryAction.cancel, id);
  }

  void _create(EditorOperation op, List<SketchEntity> out) {
    final p = op.points, b = sketch.builders;
    switch (op.tool) {
      case SketchToolType.point:
        out.add(b.point.build(p.first));
      case SketchToolType.line:
        out.add(b.line.build(p[0], p[1]));
      case SketchToolType.polyline:
        for (var i = 1; i < p.length; i++) {
          out.add(b.line.build(p[i - 1], p[i]));
        }
      case SketchToolType.rectangle:
      case SketchToolType.centerRectangle:
        final a = p[0],
            c = p[1],
            corners = [a, SketchVector(c.x, a.y), c, SketchVector(a.x, c.y)];
        for (var i = 0; i < 4; i++) {
          out.add(b.line.build(corners[i], corners[(i + 1) % 4]));
        }
      case SketchToolType.circle:
      case SketchToolType.centerCircle:
      case SketchToolType.threePointCircle:
        out.add(b.circle.build(p[0], _distance(p[0], p[1])));
      case SketchToolType.arc:
      case SketchToolType.threePointArc:
      case SketchToolType.tangentArc:
        out.add(
          b.arc.build(
            p[0],
            _distance(p[0], p[1]),
            0,
            op.parameters['endAngle'] as double? ?? math.pi,
          ),
        );
      case SketchToolType.ellipse:
        out.add(
          b.ellipse.build(p[0], _distance(p[0], p[1]), _distance(p[0], p[2])),
        );
      case SketchToolType.spline:
        out.add(b.spline.build(p));
      case SketchToolType.slot:
        out
          ..add(b.line.build(p[0], p[1]))
          ..add(
            b.arc.build(
              p[0],
              op.parameters['radius'] as double? ?? 1,
              0,
              math.pi,
            ),
          )
          ..add(
            b.arc.build(
              p[1],
              op.parameters['radius'] as double? ?? 1,
              math.pi,
              math.pi * 2,
            ),
          );
      case SketchToolType.polygon:
        final sides = op.parameters['sides'] as int? ?? p.length;
        if (sides < 3) {
          throw ArgumentError('Polygon needs at least three sides');
        }
        final center = p[0], radius = _distance(p[0], p[1]);
        final vertices = List.generate(
          sides,
          (i) => SketchVector(
            center.x + radius * math.cos(2 * math.pi * i / sides),
            center.y + radius * math.sin(2 * math.pi * i / sides),
          ),
        );
        for (var i = 0; i < sides; i++) {
          out.add(b.line.build(vertices[i], vertices[(i + 1) % sides]));
        }
      case SketchToolType.construction:
        out.add(b.construction.build(op.parameters));
      case SketchToolType.reference:
        out.add(b.reference.build(op.parameters));
      default:
        throw StateError('${op.tool.name} is an editing tool');
    }
  }

  void edit(
    SketchToolType tool,
    Iterable<String> ids, {
    SketchVector? delta,
    double value = 1,
  }) {
    if (preview.active.isEmpty) {
      throw StateError('Editing requires preview before confirmation');
    }
    final op = preview.confirm(preview.active.last.id), targets = ids.toList();
    sketch.engine.transaction('edit:${op.id}', () {
      for (final id in targets) {
        switch (tool) {
          case SketchToolType.move:
            sketch.move(id, delta ?? const SketchVector(0, 0));
            analytics.movements++;
          case SketchToolType.rotate:
            sketch.rotate(id, value);
          case SketchToolType.scale:
            sketch.scale(id, value);
          case SketchToolType.mirror:
            sketch.mirror(id);
          case SketchToolType.delete:
            sketch.deleteEntity(id);
          case SketchToolType.convertConstruction:
            sketch.setConstruction(id, true);
            analytics.conversions++;
          case SketchToolType.convertReference:
            sketch.setReference(id, true);
            analytics.conversions++;
          case SketchToolType.lock:
            sketch.engine.modify(
              id,
              SketchHistoryAction.modify,
              (e) => e.locked = true,
            );
          case SketchToolType.unlock:
            final e = sketch.entity(id) ?? (throw StateError('Unknown entity'));
            e.locked = false;
            e.version++;
          default:
            sketch.engine.modify(
              id,
              SketchHistoryAction.modify,
              (e) => e.parameters['editor:${tool.name}'] = value,
            );
        }
      }
    });
    graph.record(op.id, targets);
    _undoCounts.add(targets.length);
    _redoCounts.clear();
    history.record(EditorHistoryAction.edit, op.id);
    analytics.editCount++;
  }

  bool undo() {
    if (_undoCounts.isEmpty) return false;
    final count = _undoCounts.removeLast();
    var changed = false;
    for (var i = 0; i < count; i++) {
      changed = sketch.engine.undo() || changed;
    }
    _redoCounts.add(count);
    analytics.undo++;
    history.record(EditorHistoryAction.undo, 'editor');
    return changed;
  }

  bool redo() {
    if (_redoCounts.isEmpty) return false;
    final count = _redoCounts.removeLast();
    var changed = false;
    for (var i = 0; i < count; i++) {
      changed = sketch.engine.redo() || changed;
    }
    _undoCounts.add(count);
    analytics.redo++;
    history.record(EditorHistoryAction.redo, 'editor');
    return changed;
  }

  DegreesOfFreedom readDof() =>
      const DegreesOfFreedomReader().read(sketch, constraints, analytics);
  SketchQuality quality() {
    final q = const SketchQualityCalculator().calculate(sketch, constraints);
    analytics.sketchQuality = q.score;
    return q;
  }

  List<SketchRecommendation> recommendations() =>
      const SketchAdvisor().analyze(sketch, constraints, readDof());
  Future<void> persist() =>
      repository.save(history: history, graph: graph, analytics: analytics);
  double _distance(SketchVector a, SketchVector b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}
