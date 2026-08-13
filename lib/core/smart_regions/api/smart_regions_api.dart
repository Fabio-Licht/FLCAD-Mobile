import '../../utils/id_generator.dart';
import '../analytics/region_analytics_engine.dart';
import '../events/region_event.dart';
import '../history/region_history.dart';
import '../models/geometry.dart';
import '../models/smart_region.dart';
import '../repository/smart_region_repository.dart';
import '../selection/triangle_selection.dart';
import '../services/intent_engine.dart';

class SmartRegionsApi {
  SmartRegionsApi({SmartRegionRepository? repository, RegionEventBus? events})
    : repository = repository ?? SmartRegionRepository(),
      events = events ?? RegionEventBus();
  final SmartRegionRepository repository;
  final RegionEventBus events;
  final RegionHistory history = RegionHistory();
  final IntentEngine intents = IntentEngine();
  final RegionAnalyticsEngine analytics = const RegionAnalyticsEngine();
  Future<SmartRegion> create({
    required String projectId,
    required MeshTopology mesh,
    required TriangleSelection selection,
    required String name,
    String layerId = 'structural',
  }) async {
    final analysis = analytics.analyze(mesh, selection), now = DateTime.now();
    final region = SmartRegion(
      id: IdGenerator.generate(),
      projectId: projectId,
      meshId: mesh.id,
      dna: analysis.dna,
      name: name,
      description: '',
      color: '#2D8CFF',
      visible: true,
      locked: false,
      favorite: false,
      confidence: 1,
      layerId: layerId,
      tags: const [],
      metadata: const {},
      attributes: const {},
      createdAt: now,
      updatedAt: now,
      triangleCount: analysis.statistics.triangleCount,
      vertexCount: analysis.statistics.vertexCount,
      boundingBox: analysis.bounds,
      statistics: analysis.statistics,
      selection: selection,
    );
    final regions = await repository.loadRegions(projectId)
      ..add(region);
    await repository.saveRegions(projectId, regions);
    history.record(region.id, selection, 'created');
    events.publish(
      RegionEvent(
        type: RegionEventType.created,
        regionId: region.id,
        projectId: projectId,
        timestamp: now,
        payload: {'dna': region.dna.hash},
      ),
    );
    return region;
  }

  Future<SmartRegion> updateSelection(
    SmartRegion region,
    MeshTopology mesh,
    TriangleSelection selection,
    String reason,
  ) async {
    if (region.locked) throw StateError('Region is locked');
    final analysis = analytics.analyze(mesh, selection);
    final updated = region.copyWith(
      dna: analysis.dna,
      selection: selection,
      statistics: analysis.statistics,
      boundingBox: analysis.bounds,
      triangleCount: analysis.statistics.triangleCount,
      vertexCount: analysis.statistics.vertexCount,
      updatedAt: DateTime.now(),
    );
    final regions = await repository.loadRegions(region.projectId);
    final index = regions.indexWhere((r) => r.id == region.id);
    if (index < 0) throw StateError('Region not found');
    regions[index] = updated;
    await repository.saveRegions(region.projectId, regions);
    history.record(region.id, selection, reason);
    events.publish(
      RegionEvent(
        type: RegionEventType.updated,
        regionId: region.id,
        projectId: region.projectId,
        timestamp: DateTime.now(),
        payload: {'reason': reason},
      ),
    );
    return updated;
  }

  Future<void> delete(SmartRegion region) async {
    final regions = await repository.loadRegions(region.projectId)
      ..removeWhere((r) => r.id == region.id);
    await repository.saveRegions(region.projectId, regions);
    events.publish(
      RegionEvent(
        type: RegionEventType.deleted,
        regionId: region.id,
        projectId: region.projectId,
        timestamp: DateTime.now(),
        payload: const {},
      ),
    );
  }

  Future<SmartRegion> merge({
    required SmartRegion first,
    required SmartRegion second,
    required MeshTopology mesh,
    required String name,
  }) async {
    if (first.projectId != second.projectId || first.meshId != second.meshId) {
      throw ArgumentError('Regions must belong to the same project and mesh');
    }
    final merged = await create(
      projectId: first.projectId,
      mesh: mesh,
      selection: first.selection.union(second.selection),
      name: name,
      layerId: first.layerId,
    );
    events.publish(
      RegionEvent(
        type: RegionEventType.merged,
        regionId: merged.id,
        projectId: merged.projectId,
        timestamp: DateTime.now(),
        payload: {
          'sources': [first.id, second.id],
        },
      ),
    );
    return merged;
  }

  Future<List<SmartRegion>> split({
    required SmartRegion source,
    required MeshTopology mesh,
    required List<TriangleSelection> parts,
  }) async {
    final result = <SmartRegion>[];
    for (var i = 0; i < parts.length; i++) {
      result.add(
        await create(
          projectId: source.projectId,
          mesh: mesh,
          selection: parts[i],
          name: '${source.name} ${i + 1}',
          layerId: source.layerId,
        ),
      );
    }
    events.publish(
      RegionEvent(
        type: RegionEventType.split,
        regionId: source.id,
        projectId: source.projectId,
        timestamp: DateTime.now(),
        payload: {'derived': result.map((r) => r.id).toList()},
      ),
    );
    return result;
  }
}
