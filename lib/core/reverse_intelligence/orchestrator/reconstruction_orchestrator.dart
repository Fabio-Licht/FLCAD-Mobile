import '../../engineering/events/engineering_event_bus.dart';
import '../../smart_regions/models/geometry.dart';
import '../brain/reverse_brain.dart';
import '../knowledge/reverse_knowledge_graph.dart';

class ReconstructionOrchestrator {
  ReconstructionOrchestrator({
    ReverseBrain? brain,
    EngineeringEventBus? events,
    ReverseKnowledgeGraph? graph,
  }) : brain = brain ?? const ReverseBrain(),
       events = events ?? EngineeringEventBus(),
       graph = graph ?? ReverseKnowledgeGraph();
  final ReverseBrain brain;
  final EngineeringEventBus events;
  final ReverseKnowledgeGraph graph;
  Future<ReverseBrainResult> analyze(
    String projectId,
    MeshTopology mesh,
  ) async {
    await events.publish(
      EngineeringEvent(
        id: 'arei:${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        domain: 'reverse_intelligence',
        type: 'analysisStarted',
        entityId: mesh.id,
        timestamp: DateTime.now().toUtc(),
      ),
    );
    final result = brain.reason(projectId, mesh);
    graph.upsert(
      KnowledgeNode(mesh.id, 'mesh', {'triangles': mesh.triangles.length}),
    );
    graph.upsert(
      KnowledgeNode(result.twin.plan.id, 'reconstructionPlan', {
        'strategy': result.twin.decision.selected.id,
      }),
    );
    graph.relate(mesh.id, result.twin.plan.id, 'informs');
    await events.publish(
      EngineeringEvent(
        id: 'arei:${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        domain: 'reverse_intelligence',
        type: 'analysisCompleted',
        entityId: mesh.id,
        timestamp: DateTime.now().toUtc(),
        payload: {
          'confidence': result.twin.decision.confidence,
          'valid': result.twin.validation.valid,
        },
      ),
    );
    return result;
  }
}
