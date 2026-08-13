import '../../engineering/context/engineering_context.dart';
import '../../engineering/events/engineering_event_bus.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering/knowledge/engineering_knowledge_bus.dart';
import '../../smart_regions/models/geometry.dart';
import '../api/reverse_intelligence_api.dart';
import '../brain/reverse_brain.dart';

class ReverseEngineeringIntegration {
  const ReverseEngineeringIntegration(this.api);
  final ReverseIntelligenceApi api;
  Future<ReverseBrainResult> analyze(
    EngineeringContext context,
    MeshTopology mesh,
  ) async {
    final key = '${mesh.id}:${mesh.vertices.length}:${mesh.triangles.length}',
        cached = context.cache.get<ReverseBrainResult>('arei', key);
    if (cached != null) return cached;
    final result = await api.analyze(context.projectId, mesh);
    context.cache.put('arei', key, result);
    context.history.record(
      projectId: context.projectId,
      entityId: mesh.id,
      domain: 'reverse_intelligence',
      action: 'reasoned',
      snapshot: result.twin,
    );
    context.graph.addNode(
      EngineeringGraphNode(
        mesh.id,
        EngineeringNodeType.mesh,
        metadata: {'triangles': mesh.triangles.length},
      ),
    );
    context.graph.addNode(
      EngineeringGraphNode(
        result.twin.plan.id,
        EngineeringNodeType.ai,
        metadata: {
          'strategy': result.twin.decision.selected.id,
          'confidence': result.twin.decision.confidence,
        },
      ),
    );
    if (!context.graph.edges.any(
      (e) => e.sourceId == mesh.id && e.targetId == result.twin.plan.id,
    )) {
      context.graph.connect(
        EngineeringGraphEdge(mesh.id, result.twin.plan.id, 'informs'),
      );
    }
    await context.events.publish(
      EngineeringEvent(
        id: 'arei:context:${DateTime.now().microsecondsSinceEpoch}',
        projectId: context.projectId,
        domain: 'reverse_intelligence',
        type: 'digitalTwinUpdated',
        entityId: mesh.id,
        timestamp: DateTime.now().toUtc(),
        payload: {
          'planId': result.twin.plan.id,
          'confidence': result.twin.decision.confidence,
        },
      ),
    );
    return result;
  }

  void registerKnowledge(
    EngineeringKnowledgeBus bus,
    ReverseBrainResult result,
  ) {
    bus.register((projectId, entityId) async {
      if (projectId != result.twin.projectId ||
          entityId != result.twin.meshId) {
        return null;
      }
      return EngineeringKnowledge(
        projectId,
        entityId,
        {
          'classifications': result.twin.classifications
              .map((v) => v.toJson())
              .toList(),
          'strategy': result.twin.decision.selected.id,
          'confidence': result.twin.decision.confidence,
        },
        [result.twin.plan.id],
        ['AREI observation', 'AREI strategy validation'],
      );
    });
  }
}
