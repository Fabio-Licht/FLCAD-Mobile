import '../advisor/sketch_advisor.dart';
import '../constraints/sketch_constraint.dart';
import '../engine/sketch_engine.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch.dart';
import '../models/sketch_context.dart';

class SketchApi {
  SketchApi({SketchEngine? engine}) : _engine = engine ?? SketchEngine();
  final SketchEngine _engine;
  Future<IntelligentSketch> create({
    required String projectId,
    required String name,
    required SketchMode mode,
    required List<SketchGeometryContext> contexts,
    List<SketchEntity> entities = const [],
    List<SketchConstraint> constraints = const [],
    String? intent,
  }) => _engine.create(
    projectId: projectId,
    name: name,
    mode: mode,
    contexts: contexts,
    entities: entities,
    constraints: constraints,
    intent: intent,
  );
  Future<List<IntelligentSketch>> list(String id) =>
      _engine.repository.load(id);
  Future<IntelligentSketch> update(
    IntelligentSketch s, {
    List<SketchGeometryContext>? contexts,
    List<SketchEntity>? entities,
    List<SketchConstraint>? constraints,
    String? intent,
  }) => _engine.update(
    s,
    contexts: contexts,
    entities: entities,
    constraints: constraints,
    intent: intent,
  );
  Future<IntelligentSketch> solve(IntelligentSketch s) => _engine.solve(s);
  Future<IntelligentSketch> rebuild(
    IntelligentSketch s,
    List<SketchGeometryContext> contexts,
  ) => _engine.rebuild(s, contexts);
  Future<void> delete(IntelligentSketch s) => _engine.delete(s);
  Future<void> restore(IntelligentSketch s) => _engine.restore(s);
  Future<void> snapshot(IntelligentSketch s, String name) =>
      _engine.snapshot(s, name);
  Future<List<SketchSuggestion>> suggestions(IntelligentSketch s) =>
      _engine.suggestions(s);
}
