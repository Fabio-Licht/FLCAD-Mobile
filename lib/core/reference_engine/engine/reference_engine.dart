import '../../smart_regions/models/geometry.dart';
import '../../engineering/context/engineering_context.dart';
import '../../smart_regions/models/smart_region.dart';
import '../../utils/id_generator.dart';
import '../builders/axis_point_curve_builders.dart';
import '../builders/plane_builder.dart';
import '../builders/reference_builder.dart';
import '../cache/reference_cache.dart';
import '../events/reference_event.dart';
import '../graph/reference_graph.dart';
import '../history/reference_history.dart';
import '../models/reference_entity.dart';
import '../repository/reference_repository.dart';

class ReferenceEngine {
  ReferenceEngine({
    ReferenceRepository? repository,
    ReferenceEventBus? events,
    this.context,
  }) : repository = repository ?? ReferenceRepository(),
       events = events ?? ReferenceEventBus() {
    for (final b in <ReferenceBuilder>[
      PlaneBuilder(),
      AxisBuilder(),
      PointBuilder(),
      CurveBuilder(),
      CoordinateSystemBuilder(),
    ]) {
      builders[b.id] = b;
    }
  }
  final ReferenceRepository repository;
  final EngineeringContext? context;
  final ReferenceEventBus events;
  final Map<String, ReferenceBuilder> builders = {};
  final Map<String, ReferenceGraph> _graphs = {};
  final ReferenceHistory history = ReferenceHistory();
  final ReferenceCache cache = ReferenceCache();
  Future<ReferenceGraph> graphFor(String projectId) async =>
      _graphs[projectId] ??= await repository.loadGraph(projectId);
  Future<ReferenceEntity> create({
    required String projectId,
    required String name,
    required ReferenceMode mode,
    required ReferenceRecipe recipe,
    required Map<String, MeshTopology> meshes,
    required Map<String, SmartRegion> regions,
  }) async {
    final existing = await repository.load(projectId),
        map = {for (final r in existing) r.id: r},
        builder = builders[recipe.builderId];
    if (builder == null) {
      throw StateError('Builder not registered: ${recipe.builderId}');
    }
    final context = ReferenceBuildContext(
          projectId: projectId,
          meshes: meshes,
          regions: regions,
          references: map,
        ),
        fingerprint = _fingerprint(recipe, regions, map);
    var result = cache.read(builder.id, fingerprint);
    result ??= await builder.build(context, recipe);
    cache.write(builder.id, fingerprint, result);
    final now = DateTime.now(),
        dna = createReferenceDNA(
          builder.id,
          result.sourceFingerprint,
          result.geometry,
        );
    final entity = ReferenceEntity(
      id: IdGenerator.generate(),
      projectId: projectId,
      name: name,
      geometry: result.geometry,
      mode: mode,
      status: ReferenceStatus.valid,
      dna: dna,
      analytics: result.analytics,
      recipe: recipe,
      version: 1,
      createdAt: now,
      updatedAt: now,
      dependencies: recipe.sourceIds,
      metadata: const {},
    );
    existing.add(entity);
    final graph = await graphFor(projectId);
    graph.add(entity.id);
    for (final source in recipe.sourceIds) {
      graph.add(source);
      graph.connect(source, entity.id, 'derives');
    }
    await repository.save(projectId, existing);
    await repository.saveGraph(projectId, graph);
    history.record(entity, 'created');
    await _persistHistory(projectId);
    events.publish(
      ReferenceEvent(ReferenceEventType.created, entity.id, projectId, now, {
        'dna': dna.hash,
      }),
    );
    return entity;
  }

  Future<ReferenceEntity> rebuild(
    ReferenceEntity reference, {
    required Map<String, MeshTopology> meshes,
    required Map<String, SmartRegion> regions,
  }) async {
    if (reference.mode != ReferenceMode.live) return reference;
    final all = await repository.load(reference.projectId),
        map = {for (final r in all) r.id: r},
        builder = builders[reference.recipe.builderId];
    if (builder == null) throw StateError('Builder unavailable');
    final result = await builder.build(
          ReferenceBuildContext(
            projectId: reference.projectId,
            meshes: meshes,
            regions: regions,
            references: map,
          ),
          reference.recipe,
        ),
        updated = reference.copyWith(
          geometry: result.geometry,
          analytics: result.analytics,
          dna: createReferenceDNA(
            builder.id,
            result.sourceFingerprint,
            result.geometry,
          ),
          status: ReferenceStatus.valid,
          version: reference.version + 1,
          updatedAt: DateTime.now(),
        );
    final index = all.indexWhere((r) => r.id == reference.id);
    all[index] = updated;
    await repository.save(reference.projectId, all);
    history.record(updated, 'rebuilt');
    await _persistHistory(reference.projectId);
    events.publish(
      ReferenceEvent(
        ReferenceEventType.rebuilt,
        updated.id,
        updated.projectId,
        DateTime.now(),
        {'version': updated.version},
      ),
    );
    return updated;
  }

  Future<void> delete(ReferenceEntity reference) async {
    final all = await repository.load(reference.projectId)
      ..removeWhere((r) => r.id == reference.id);
    await repository.save(reference.projectId, all);
    final graph = await graphFor(reference.projectId);
    graph.remove(reference.id);
    await repository.saveGraph(reference.projectId, graph);
    history.record(reference, 'deleted');
    await _persistHistory(reference.projectId);
    events.publish(
      ReferenceEvent(
        ReferenceEventType.deleted,
        reference.id,
        reference.projectId,
        DateTime.now(),
        const {},
      ),
    );
  }

  Future<void> restore(ReferenceEntity reference) async {
    final all = await repository.load(reference.projectId);
    all.removeWhere((r) => r.id == reference.id);
    all.add(reference);
    await repository.save(reference.projectId, all);
    history.record(reference, 'restored');
    await _persistHistory(reference.projectId);
  }

  Future<List<ReferenceEntity>> synchronizeLive(
    String projectId, {
    required Map<String, MeshTopology> meshes,
    required Map<String, SmartRegion> regions,
  }) async {
    final all = await repository.load(projectId), output = <ReferenceEntity>[];
    for (final reference in all) {
      output.add(
        reference.mode == ReferenceMode.live
            ? await rebuild(reference, meshes: meshes, regions: regions)
            : reference,
      );
    }
    return output;
  }

  Future<bool> validate(ReferenceEntity reference) async {
    final valid =
        reference.geometry.toJson().isNotEmpty &&
        reference.analytics.confidence >= 0 &&
        reference.analytics.confidence <= 1;
    events.publish(
      ReferenceEvent(
        ReferenceEventType.validated,
        reference.id,
        reference.projectId,
        DateTime.now(),
        {'valid': valid},
      ),
    );
    return valid;
  }

  String _fingerprint(
    ReferenceRecipe recipe,
    Map<String, SmartRegion> regions,
    Map<String, ReferenceEntity> references,
  ) => recipe.sourceIds
      .map((id) => regions[id]?.dna.hash ?? references[id]?.dna.hash ?? id)
      .join(':');
  Future<void> _persistHistory(String projectId) => repository.saveHistory(
    projectId,
    history.all
        .map(
          (v) => {
            'referenceId': v.reference.id,
            'version': v.version,
            'reason': v.reason,
            'timestamp': v.timestamp.toIso8601String(),
          },
        )
        .toList(),
  );
}
