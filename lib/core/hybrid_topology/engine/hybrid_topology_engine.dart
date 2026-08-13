import '../../adaptive_surface/graph/surface_graph.dart';
import '../../engineering/context/engineering_context.dart';
import '../../smart_regions/models/geometry.dart';
import '../../utils/id_generator.dart';
import '../analytics/topology_quality_engine.dart';
import '../constraints/topology_constraint.dart';
import '../events/topology_event.dart';
import '../history/topology_history.dart';
import '../hybrid/hybrid_object.dart';
import '../layers/mesh_layer.dart';
import '../learning/topology_learning.dart';
import '../models/topology_dna.dart';
import '../morphing/mesh_morph_engine.dart';
import '../serialization/topology_repository.dart';
import '../workspace/local_workspace.dart';

class HybridTopologyEngine {
  HybridTopologyEngine({
    TopologyRepository? repository,
    TopologyEventBus? events,
    TopologyLearningSink? learning,
    this.context,
  }) : repository = repository ?? TopologyRepository(),
       events = events ?? TopologyEventBus(),
       learning = learning ?? const NoOpTopologyLearningSink();
  final TopologyRepository repository;
  final EngineeringContext? context;
  final TopologyEventBus events;
  final TopologyLearningSink learning;
  final TopologyHistory history = TopologyHistory();
  final Map<String, List<HybridObject>> objects = {};
  final Map<String, List<MeshLayer>> layers = {};
  final Map<String, List<LocalWorkspace>> workspaces = {};
  final Map<String, List<TopologyConstraint>> constraints = {};
  final Map<String, ReverseEngineeringKnowledgeGraph> graphs = {};
  Future<HybridObject> create({
    required String projectId,
    required String name,
    required GeometryAssetRef meshAsset,
    required MeshTopology mesh,
    List<String> regionIds = const [],
    List<String> referenceIds = const [],
    List<String> sketchIds = const [],
    List<String> surfaceIds = const [],
  }) async {
    final now = DateTime.now(),
        original = MeshLayer(
          id: IdGenerator.generate(),
          objectId: 'pending',
          name: 'Original',
          kind: MeshLayerKind.original,
          enabled: true,
          locked: true,
          opacity: 1,
          blendMode: LayerBlendMode.replace,
          displacements: const {},
          createdAt: now,
        ),
        id = IdGenerator.generate(),
        fixed = MeshLayer(
          id: original.id,
          objectId: id,
          name: original.name,
          kind: original.kind,
          enabled: true,
          locked: true,
          opacity: 1,
          blendMode: original.blendMode,
          displacements: const {},
          createdAt: now,
        ),
        object = HybridObject(
          id: id,
          projectId: projectId,
          name: name,
          mode: HybridObjectMode.live,
          assets: [meshAsset],
          regionIds: regionIds,
          referenceIds: referenceIds,
          sketchIds: sketchIds,
          surfaceIds: surfaceIds,
          solidIds: const [],
          layerIds: [fixed.id],
          dna: createTopologyDNA([meshAsset], [fixed], [
            ...regionIds,
            ...referenceIds,
            ...sketchIds,
            ...surfaceIds,
          ]),
          analytics: const TopologyQualityEngine().analyze(mesh),
          version: 1,
          createdAt: now,
          updatedAt: now,
        );
    (objects[projectId] ??= []).add(object);
    (layers[projectId] ??= []).add(fixed);
    final graph = graphs[projectId] ??= ReverseEngineeringKnowledgeGraph();
    graph.add(
      EngineeringNode(id, EngineeringNodeKind.mesh, {'hybridObject': true}),
    );
    history.record(object, 'created');
    await _persist(projectId);
    _emit(object, TopologyEventType.created, 'created');
    return object;
  }

  Future<HybridObject> morph(
    HybridObject object,
    MeshTopology mesh,
    MorphRequest request, {
    MeshLayerKind kind = MeshLayerKind.compensation,
  }) async {
    final result = const MeshMorphEngine().apply(
          mesh,
          request,
          constraints[object.projectId] ?? const [],
        ),
        layer = MeshLayer(
          id: IdGenerator.generate(),
          objectId: object.id,
          name: request.operation.name,
          kind: kind,
          enabled: true,
          locked: false,
          opacity: 1,
          blendMode: LayerBlendMode.additive,
          displacements: result.displacements,
          createdAt: DateTime.now(),
          metadata: {'warnings': result.warnings},
        ),
        allLayers = layers[object.projectId] ??= [];
    allLayers.add(layer);
    final updated = object.copyWith(
      layerIds: [...object.layerIds, layer.id],
      dna: createTopologyDNA(object.assets, allLayers, [
        ...object.regionIds,
        ...object.referenceIds,
        ...object.sketchIds,
        ...object.surfaceIds,
      ]),
      version: object.version + 1,
      updatedAt: DateTime.now(),
    );
    _replace(updated);
    history.record(updated, 'morphed');
    await _persist(object.projectId);
    _emit(updated, TopologyEventType.morphed, 'morphed');
    return updated;
  }

  void addConstraint(String projectId, TopologyConstraint value) =>
      (constraints[projectId] ??= []).add(value);
  void addWorkspace(LocalWorkspace value) =>
      (workspaces[value.projectId] ??= []).add(value);
  Future<void> _persist(String id) async {
    await repository.saveTopology(id, objects[id] ?? const []);
    await repository.saveLayers(id, layers[id] ?? const []);
    await repository.saveWorkspaces(id, workspaces[id] ?? const []);
    await repository.saveConstraints(id, constraints[id] ?? const []);
    await repository.saveHistory(
      id,
      history.all.map((e) => e.toJson()).toList(),
    );
    await repository.saveGraph(
      id,
      graphs[id] ?? ReverseEngineeringKnowledgeGraph(),
    );
  }

  void _replace(HybridObject o) {
    final list = objects[o.projectId]!,
        i = list.indexWhere((v) => v.id == o.id);
    list[i] = o;
  }

  void _emit(HybridObject o, TopologyEventType type, String action) {
    events.publish(
      TopologyEvent(type, o.id, o.projectId, DateTime.now(), {
        'version': o.version,
      }),
    );
    learning.record(
      TopologyLearningEvent(o.projectId, o.id, action, DateTime.now()),
    );
  }
}
