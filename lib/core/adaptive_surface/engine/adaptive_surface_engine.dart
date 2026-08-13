import '../../utils/id_generator.dart';
import '../../engineering/context/engineering_context.dart';
import '../advisor/surface_advisor.dart';
import '../builders/primitive_surface_builders.dart';
import '../builders/procedural_surface_builder.dart';
import '../builders/surface_builder.dart';
import '../cache/surface_cache.dart';
import '../events/surface_event.dart';
import '../graph/surface_graph.dart';
import '../history/surface_history.dart';
import '../intent/surface_intent_engine.dart';
import '../learning/surface_learning.dart';
import '../models/adaptive_surface.dart';
import '../models/surface_dna.dart';
import '../network/surface_network.dart';
import '../optimization/global_surface_optimizer.dart';
import '../quality/surface_quality_engine.dart';
import '../repair/surface_repair_engine.dart';
import '../serialization/surface_repository.dart';
import '../solver/adaptive_surface_solver.dart';
import '../validation/surface_validator.dart';

class AdaptiveSurfaceEngine {
  AdaptiveSurfaceEngine({
    SurfaceRepository? repository,
    AdaptiveSurfaceSolver? solver,
    SurfaceEventBus? events,
    SurfaceLearningSink? learning,
    SurfaceAdvisor? advisor,
    this.context,
  }) : repository = repository ?? SurfaceRepository(),
       solver =
           solver ??
           AdaptiveSurfaceSolver([
             PlaneSurfaceBuilder(),
             SphereSurfaceBuilder(),
             PatchSurfaceBuilder(),
             ProceduralSurfaceBuilder(),
           ]),
       events = events ?? SurfaceEventBus(),
       learning = learning ?? const NoOpSurfaceLearningSink(),
       advisor = advisor ?? const RuleBasedSurfaceAdvisor();
  final SurfaceRepository repository;
  final EngineeringContext? context;
  final AdaptiveSurfaceSolver solver;
  final SurfaceEventBus events;
  final SurfaceLearningSink learning;
  final SurfaceAdvisor advisor;
  final SurfaceCache cache = SurfaceCache();
  final SurfaceHistory history = SurfaceHistory();
  final Map<String, SurfaceGraph> _graphs = {};
  Future<SurfaceGraph> graphFor(String id) async =>
      _graphs[id] ??= await repository.loadGraph(id);
  Future<AdaptiveSurface> create({
    required String projectId,
    required String name,
    required SurfaceBuildRequest request,
    SurfaceMode mode = SurfaceMode.live,
    SurfaceStage stage = SurfaceStage.alpha,
    ManufacturingProcess manufacturingProcess = ManufacturingProcess.unknown,
    Map<String, EngineeringNodeKind> sourceKinds = const {},
  }) async {
    final intent = const SurfaceIntentEngine().infer(
          declaredIntent: request.intent,
          process: manufacturingProcess,
        ),
        result = await _solve(request),
        candidate = result.best,
        score = const SurfaceQualityEngine().score(candidate.metrics, intent),
        now = DateTime.now(),
        surface = AdaptiveSurface(
          id: IdGenerator.generate(),
          projectId: projectId,
          name: name,
          geometry: candidate.geometry,
          mode: mode,
          stage: stage,
          status: SurfaceStatus.valid,
          sourceIds: request.sourceIds,
          neighborIds: const [],
          dna: createSurfaceDNA(
            request.sourceIds,
            candidate.geometry,
            intent.kind,
          ),
          metrics: candidate.metrics,
          score: score,
          intent: intent.kind,
          manufacturingProcess: manufacturingProcess,
          version: 1,
          createdAt: now,
          updatedAt: now,
          metadata: {
            'solver': candidate.solverId,
            'sourceFingerprint': request.fingerprint,
            'candidateScores': result.scores,
          },
        );
    final all = await repository.load(projectId)
          ..add(surface),
        graph = await graphFor(projectId)
          ..add(
            EngineeringNode(surface.id, EngineeringNodeKind.surface, {
              'dna': surface.dna.hash,
            }),
          );
    for (final source in request.sourceIds) {
      graph.add(
        EngineeringNode(
          source,
          sourceKinds[source] ?? EngineeringNodeKind.region,
          const {},
        ),
      );
      graph.connect(source, surface.id, 'derives');
    }
    history.record(surface, 'created');
    await _persist(projectId, all, graph);
    await _after(surface, SurfaceEventType.created, 'created');
    return surface;
  }

  Future<AdaptiveSurface> rebuild(
    AdaptiveSurface source,
    SurfaceBuildRequest request,
  ) async {
    if (source.mode == SurfaceMode.staticSurface ||
        request.fingerprint == source.metadata['sourceFingerprint']) {
      return source;
    }
    final solved = await _solve(request),
        candidate = solved.best,
        intent = const SurfaceIntentEngine().infer(
          declaredIntent: source.intent,
          process: source.manufacturingProcess,
        ),
        updated = source.copyWith(
          geometry: candidate.geometry,
          dna: createSurfaceDNA(
            request.sourceIds,
            candidate.geometry,
            source.intent,
          ),
          metrics: candidate.metrics,
          score: const SurfaceQualityEngine().score(candidate.metrics, intent),
          status: SurfaceStatus.valid,
          version: source.version + 1,
          updatedAt: DateTime.now(),
          metadata: {
            ...source.metadata,
            'sourceFingerprint': request.fingerprint,
            'solver': candidate.solverId,
          },
        );
    await _replace(updated);
    history.record(updated, 'rebuilt');
    await _after(updated, SurfaceEventType.rebuilt, 'rebuilt');
    return updated;
  }

  Future<AdaptiveSurface> refine(
    AdaptiveSurface source,
    SurfaceStage target,
  ) async {
    if (target.index < source.stage.index) {
      throw ArgumentError('Progressive stage cannot move backwards');
    }
    final updated = source.copyWith(
      stage: target,
      version: source.version + 1,
      updatedAt: DateTime.now(),
    );
    await _replace(updated);
    history.record(updated, 'refined');
    await _after(updated, SurfaceEventType.refined, 'refined');
    return updated;
  }

  Future<AdaptiveSurface> repair(
    AdaptiveSurface source,
    Set<SurfaceRepairAction> actions,
  ) async {
    final updated = const SurfaceRepairEngine().repair(source, actions);
    await _replace(updated);
    history.record(updated, 'repaired');
    await _after(updated, SurfaceEventType.repaired, 'repaired');
    return updated;
  }

  Future<bool> validate(
    AdaptiveSurface source, {
    SurfaceValidator validator = const SurfaceValidator(),
  }) async {
    final result = validator.validate(source);
    events.publish(
      SurfaceEvent(
        SurfaceEventType.validated,
        source.id,
        source.projectId,
        DateTime.now(),
        {'valid': result.valid, 'issues': result.issues},
      ),
    );
    return result.valid;
  }

  Future<GlobalOptimizationResult> optimizeNetwork(
    SurfaceNetwork network, {
    GlobalSurfaceOptimizer optimizer = const GlobalSurfaceOptimizer(),
  }) async {
    final result = await optimizer.optimize(network);
    await repository.saveNetwork(network.surfaces.values.first.projectId, {
      'surfaceIds': result.network.surfaces.keys.toList(),
      'constraints': result.network.constraints
          .map((value) => value.toJson())
          .toList(),
      'initialScore': result.initialScore,
      'finalScore': result.finalScore,
      'iterations': result.iterations,
    });
    for (final surface in result.network.surfaces.values) {
      events.publish(
        SurfaceEvent(
          SurfaceEventType.optimized,
          surface.id,
          surface.projectId,
          DateTime.now(),
          {'global': true},
        ),
      );
    }
    return result;
  }

  Future<void> delete(AdaptiveSurface source) async {
    final all = await repository.load(source.projectId)
          ..removeWhere((s) => s.id == source.id),
        graph = await graphFor(source.projectId)
          ..remove(source.id);
    history.record(source, 'deleted');
    await _persist(source.projectId, all, graph);
    await _after(source, SurfaceEventType.deleted, 'deleted');
  }

  Future<void> restore(AdaptiveSurface source) async {
    final all = await repository.load(source.projectId)
          ..removeWhere((s) => s.id == source.id)
          ..add(source),
        graph = await graphFor(source.projectId)
          ..add(
            EngineeringNode(source.id, EngineeringNodeKind.surface, {
              'dna': source.dna.hash,
            }),
          );
    for (final id in source.sourceIds) {
      if (!graph.nodes.containsKey(id)) {
        graph.add(EngineeringNode(id, EngineeringNodeKind.region, const {}));
      }
      graph.connect(id, source.id, 'derives');
    }
    history.record(source, 'restored');
    await _persist(source.projectId, all, graph);
  }

  Future<SurfaceSolverResult> _solve(SurfaceBuildRequest request) async {
    final cached = cache.read(request.fingerprint);
    if (cached != null) return cached;
    final result = await solver.solve(request);
    cache.write(request.fingerprint, result);
    return result;
  }

  Future<void> _replace(AdaptiveSurface value) async {
    final all = await repository.load(value.projectId),
        index = all.indexWhere((s) => s.id == value.id);
    if (index < 0) throw StateError('Surface not found');
    all[index] = value;
    await _persist(value.projectId, all, await graphFor(value.projectId));
  }

  Future<void> _persist(
    String id,
    List<AdaptiveSurface> values,
    SurfaceGraph graph,
  ) async {
    await repository.save(id, values);
    await repository.saveGraph(id, graph);
    await repository.saveHistory(
      id,
      history.all.map((v) => v.toJson()).toList(),
    );
  }

  Future<void> _after(
    AdaptiveSurface s,
    SurfaceEventType type,
    String action,
  ) async {
    await repository.saveHistory(
      s.projectId,
      history.all.map((v) => v.toJson()).toList(),
    );
    events.publish(
      SurfaceEvent(type, s.id, s.projectId, DateTime.now(), {
        'version': s.version,
        'stage': s.stage.name,
        'score': s.score.total,
      }),
    );
    await learning.record(
      SurfaceLearningEvent(s.projectId, s.id, action, DateTime.now(), {
        'intent': s.intent,
        'score': s.score.total,
      }),
    );
  }
}
