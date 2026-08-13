import '../../utils/id_generator.dart';
import '../../engineering/context/engineering_context.dart';
import '../builders/feature_builder.dart';
import '../cache/feature_cache.dart';
import '../events/parametric_event.dart';
import '../features/engineering_feature.dart';
import '../features/feature_dna.dart';
import '../graph/feature_graph.dart';
import '../history/parametric_history.dart';
import '../kernel/geometry_kernel_adapter.dart';
import '../serialization/parametric_repository.dart';
import '../solids/engineering_solid.dart';
import '../timeline/engineering_timeline.dart';
import '../validators/engineering_validators.dart';

class ParametricEngineeringEngine {
  ParametricEngineeringEngine({
    ParametricRepository? repository,
    GeometryKernelAdapter? kernel,
    ParametricEventBus? events,
    this.context,
  }) : repository = repository ?? ParametricRepository(),
       kernel = kernel ?? const UnavailableGeometryKernel(),
       events = events ?? ParametricEventBus();
  final ParametricRepository repository;
  final EngineeringContext? context;
  final GeometryKernelAdapter kernel;
  final ParametricEventBus events;
  final ParametricHistory history = ParametricHistory();
  final EngineeringTimeline timeline = EngineeringTimeline();
  final FeatureCache cache = FeatureCache();
  final Map<String, List<EngineeringFeature>> features = {};
  final Map<String, List<EngineeringSolid>> solids = {};
  final Map<String, FeatureGraph> graphs = {};
  Future<EngineeringFeature> createFeature(
    FeatureRecipe recipe, {
    String branch = 'main',
  }) async {
    var feature = const FeatureBuilder().build(recipe);
    final cached = cache.read(feature.dna.hash);
    if (cached != null) {
      feature = feature.copyWith(
        status: FeatureStatus.valid,
        kernelResultId: cached.id,
      );
    } else if (kernel.capabilities.features.contains(feature.kind)) {
      final handle = await kernel.executeFeature(feature, const []);
      cache.write(feature.dna.hash, handle);
      feature = feature.copyWith(
        status: FeatureStatus.valid,
        kernelResultId: handle.id,
      );
    }
    (features[recipe.projectId] ??= []).add(feature);
    final graph = graphs[recipe.projectId] ??= FeatureGraph();
    graph.add(
      EngineeringNode(feature.id, EngineeringNodeKind.solid, {
        'entityType': 'feature',
        'dna': feature.dna.hash,
      }),
    );
    for (final source in feature.sourceIds) {
      if (!graph.nodes.containsKey(source)) {
        graph.add(
          EngineeringNode(source, EngineeringNodeKind.sketch, const {}),
        );
      }
      graph.connect(source, feature.id, 'drives');
    }
    history.record(feature, 'created', branchId: branch);
    _decision(feature, 'create-feature', feature.intent, branch);
    await _persist(recipe.projectId);
    events.publish(
      ParametricEvent(
        ParametricEventType.featureCreated,
        feature.id,
        recipe.projectId,
        DateTime.now(),
        {'status': feature.status.name},
      ),
    );
    return feature;
  }

  Future<EngineeringFeature> rebuild(
    EngineeringFeature source,
    Map<String, dynamic> parameters,
  ) async {
    if (source.mode == FeatureMode.staticFeature) return source;
    final dna = createFeatureDNA(
      origins: source.sourceIds,
      intent: source.intent,
      parameters: parameters,
      manufacturing: source.manufacturing,
      inspection: source.inspection,
      relations: [...source.dependencyIds, ...source.referenceIds],
    );
    if (dna.hash == source.dna.hash) return source;
    var updated = source.copyWith(
      parameters: parameters,
      dna: dna,
      status: FeatureStatus.pendingKernel,
      version: source.version + 1,
      updatedAt: DateTime.now(),
    );
    if (kernel.capabilities.features.contains(updated.kind)) {
      final handle = await kernel.executeFeature(updated, const []);
      updated = updated.copyWith(
        status: FeatureStatus.valid,
        kernelResultId: handle.id,
      );
    }
    final list = features[source.projectId]!,
        i = list.indexWhere((f) => f.id == source.id);
    list[i] = updated;
    history.record(updated, 'rebuilt');
    _decision(
      updated,
      'rebuild-feature',
      'Source or parameters changed',
      'main',
    );
    await _persist(source.projectId);
    return updated;
  }

  Future<EngineeringSolid> createSolid(
    String projectId,
    String name,
    List<EngineeringFeature> inputs,
  ) async {
    final handles = <SolidHandle>[];
    for (final f in inputs) {
      final h = cache.read(f.dna.hash);
      if (h != null) handles.add(h);
    }
    final now = DateTime.now(),
        solid = EngineeringSolid(
          id: IdGenerator.generate(),
          projectId: projectId,
          name: name,
          featureIds: inputs.map((e) => e.id).toList(),
          sourceIds: inputs.expand((e) => e.sourceIds).toSet().toList(),
          version: 1,
          createdAt: now,
          updatedAt: now,
          handle: handles.isEmpty ? null : handles.last,
          metadata: {'pendingKernel': handles.isEmpty},
        );
    (solids[projectId] ??= []).add(solid);
    await _persist(projectId);
    events.publish(
      ParametricEvent(
        ParametricEventType.solidCreated,
        solid.id,
        projectId,
        now,
        {'hasKernelHandle': solid.handle != null},
      ),
    );
    return solid;
  }

  ValidationReport validateFeature(EngineeringFeature f) =>
      const FeatureValidator().validate(f);
  ValidationReport validateSolid(EngineeringSolid s) =>
      const SolidValidator().validate(s);
  void createBranch(String projectId, TimelineBranch b) {
    timeline.branch(b);
    events.publish(
      ParametricEvent(
        ParametricEventType.branchCreated,
        b.id,
        projectId,
        DateTime.now(),
        const {},
      ),
    );
  }

  void _decision(
    EngineeringFeature f,
    String action,
    String reason,
    String branch,
  ) => timeline.append(
    EngineeringDecision(
      id: IdGenerator.generate(),
      projectId: f.projectId,
      branchId: branch,
      entityId: f.id,
      action: action,
      reason: reason,
      timestamp: DateTime.now(),
      sequence: timeline.decisions.length + 1,
      parameters: f.parameters,
    ),
  );
  Future<void> _persist(String id) async {
    await repository.saveFeatures(id, features[id] ?? const []);
    await repository.saveGraph(id, graphs[id] ?? FeatureGraph());
    await repository.saveHistory(
      id,
      history.all.map((e) => e.toJson()).toList(),
    );
    await repository.saveTimeline(id, timeline);
    await repository.saveSolids(id, solids[id] ?? const []);
  }
}
