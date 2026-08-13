import '../../utils/id_generator.dart';
import '../../engineering/context/engineering_context.dart';
import '../advisor/sketch_advisor.dart';
import '../analytics/sketch_analytics_engine.dart';
import '../cache/sketch_cache.dart';
import '../constraints/sketch_constraint.dart';
import '../entities/sketch_entity.dart';
import '../events/sketch_event.dart';
import '../graph/sketch_graph.dart';
import '../history/sketch_history.dart';
import '../learning/sketch_learning.dart';
import '../models/sketch.dart';
import '../models/sketch_context.dart';
import '../models/sketch_dna.dart';
import '../serialization/sketch_repository.dart';
import '../solver/adaptive_constraint_solver.dart';

class SketchEngine {
  SketchEngine({
    SketchRepository? repository,
    AdaptiveConstraintSolver? solver,
    SketchAdvisor? advisor,
    SketchLearningSink? learning,
    SketchEventBus? events,
    this.context,
  }) : repository = repository ?? SketchRepository(),
       solver = solver ?? AdaptiveConstraintSolver(),
       advisor = advisor ?? const RuleBasedSketchAdvisor(),
       learning = learning ?? const NoOpSketchLearningSink(),
       events = events ?? SketchEventBus();
  final SketchRepository repository;
  final EngineeringContext? context;
  final AdaptiveConstraintSolver solver;
  final SketchAdvisor advisor;
  final SketchLearningSink learning;
  final SketchEventBus events;
  final SketchHistory history = SketchHistory();
  final SketchCache cache = SketchCache();
  final Map<String, SketchGraph> _graphs = {};
  Future<SketchGraph> graphFor(String projectId) async =>
      _graphs[projectId] ??= await repository.loadGraph(projectId);
  Future<IntelligentSketch> create({
    required String projectId,
    required String name,
    required SketchMode mode,
    required List<SketchGeometryContext> contexts,
    List<SketchEntity> entities = const [],
    List<SketchConstraint> constraints = const [],
    String? intent,
  }) async {
    final now = DateTime.now(),
        analytics = const SketchAnalyticsEngine().evaluate(entities),
        dna = createSketchDNA(contexts, entities),
        sketch = IntelligentSketch(
          id: IdGenerator.generate(),
          projectId: projectId,
          name: name,
          mode: mode,
          status: SketchStatus.created,
          contexts: List.unmodifiable(contexts),
          entities: List.unmodifiable(entities),
          constraints: List.unmodifiable(constraints),
          dna: dna,
          analytics: analytics,
          version: 1,
          createdAt: now,
          updatedAt: now,
          intent: intent,
        );
    final all = await repository.load(projectId)
      ..add(sketch);
    final graph = await graphFor(projectId)
      ..add(sketch.id);
    for (final context in contexts) {
      graph.add(context.sourceId);
      graph.connect(context.sourceId, sketch.id, 'context');
    }
    await _persist(projectId, all, graph);
    cache.write(sketch.dna.hash, sketch);
    history.record(sketch, 'created');
    await _after(sketch, SketchEventType.created, 'created');
    return sketch;
  }

  Future<IntelligentSketch> update(
    IntelligentSketch source, {
    List<SketchGeometryContext>? contexts,
    List<SketchEntity>? entities,
    List<SketchConstraint>? constraints,
    String? intent,
  }) async {
    final nextContexts = contexts ?? source.contexts,
        nextEntities = entities ?? source.entities,
        now = DateTime.now(),
        updated = source.copyWith(
          contexts: nextContexts,
          entities: nextEntities,
          constraints: constraints,
          dna: createSketchDNA(nextContexts, nextEntities),
          analytics: const SketchAnalyticsEngine().evaluate(nextEntities),
          version: source.version + 1,
          updatedAt: now,
          intent: intent,
        );
    await _replace(updated);
    history.record(updated, 'updated');
    await _after(updated, SketchEventType.updated, 'updated');
    return updated;
  }

  Future<IntelligentSketch> solve(IntelligentSketch source) async {
    final solveKey =
            '${source.dna.hash}:${source.constraints.map((value) => value.toJson()).join('|')}',
        cached = cache.read(solveKey);
    if (cached != null) return cached;
    final result = solver.solve(source.entities, source.constraints),
        status = result.overConstrained
            ? SketchStatus.overConstrained
            : result.remainingDegreesOfFreedom == 0
            ? SketchStatus.solved
            : SketchStatus.underConstrained,
        updated = source.copyWith(
          entities: result.entities,
          status: status,
          dna: createSketchDNA(source.contexts, result.entities),
          analytics: const SketchAnalyticsEngine().evaluate(result.entities),
          version: source.version + 1,
          updatedAt: DateTime.now(),
          metadata: {
            ...source.metadata,
            'degreesOfFreedom': result.remainingDegreesOfFreedom,
            'diagnostics': result.diagnostics
                .map(
                  (d) => {
                    'constraintId': d.constraintId,
                    'state': d.state.name,
                    'error': d.error,
                    'explanation': d.explanation,
                    'suggestion': d.suggestion,
                  },
                )
                .toList(),
          },
        );
    await _replace(updated);
    history.record(updated, 'solved');
    cache.write(solveKey, updated);
    await _after(updated, SketchEventType.solved, 'solved');
    return updated;
  }

  Future<IntelligentSketch> rebuild(
    IntelligentSketch source,
    List<SketchGeometryContext> contexts,
  ) async {
    if (source.mode == SketchMode.staticSketch) return source;
    if (createSketchDNA(contexts, source.entities).contextSignature ==
        source.dna.contextSignature) {
      return source;
    }
    return update(source, contexts: contexts);
  }

  Future<void> delete(IntelligentSketch sketch) async {
    final all = await repository.load(sketch.projectId)
          ..removeWhere((s) => s.id == sketch.id),
        graph = await graphFor(sketch.projectId)
          ..remove(sketch.id);
    await _persist(sketch.projectId, all, graph);
    history.record(sketch, 'deleted');
    await _after(sketch, SketchEventType.deleted, 'deleted');
  }

  Future<void> restore(IntelligentSketch sketch) async {
    final all = await repository.load(sketch.projectId)
          ..removeWhere((s) => s.id == sketch.id)
          ..add(sketch),
        graph = await graphFor(sketch.projectId)
          ..add(sketch.id);
    for (final context in sketch.contexts) {
      graph.add(context.sourceId);
      graph.connect(context.sourceId, sketch.id, 'context');
    }
    await _persist(sketch.projectId, all, graph);
    history.record(sketch, 'restored');
    await repository.saveHistory(
      sketch.projectId,
      history.all.map((value) => value.toJson()).toList(),
    );
  }

  Future<List<SketchSuggestion>> suggestions(IntelligentSketch sketch) =>
      advisor.advise(sketch);
  Future<void> snapshot(IntelligentSketch sketch, String name) =>
      repository.saveSnapshot(sketch.projectId, name, sketch);
  Future<void> _replace(IntelligentSketch sketch) async {
    final all = await repository.load(sketch.projectId),
        index = all.indexWhere((s) => s.id == sketch.id);
    if (index < 0) throw StateError('Sketch not found');
    all[index] = sketch;
    await _persist(sketch.projectId, all, await graphFor(sketch.projectId));
  }

  Future<void> _persist(
    String id,
    List<IntelligentSketch> values,
    SketchGraph graph,
  ) async {
    await repository.save(id, values);
    await repository.saveGraph(id, graph);
    await repository.saveConstraints(id, values);
    await repository.saveHistory(
      id,
      history.all.map((v) => v.toJson()).toList(),
    );
  }

  Future<void> _after(
    IntelligentSketch sketch,
    SketchEventType type,
    String action,
  ) async {
    await repository.saveHistory(
      sketch.projectId,
      history.all.map((value) => value.toJson()).toList(),
    );
    events.publish(
      SketchEvent(type, sketch.id, sketch.projectId, DateTime.now(), {
        'version': sketch.version,
        'dna': sketch.dna.hash,
      }),
    );
    await learning.record(
      SketchLearningEvent(sketch.projectId, sketch.id, action, DateTime.now(), {
        'version': sketch.version,
      }),
    );
  }
}
