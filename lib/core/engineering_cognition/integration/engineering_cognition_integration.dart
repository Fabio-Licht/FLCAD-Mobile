import '../../engineering/context/engineering_context.dart';
import '../../engineering/events/engineering_event_bus.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../../smart_regions/models/smart_region.dart';
import '../api/engineering_cognition_api.dart';
import '../orchestrator/cognition_orchestrator.dart';

class EngineeringCognitionIntegration {
  const EngineeringCognitionIntegration(this.api);
  final EngineeringCognitionApi api;
  Future<CognitionResult> analyze(
    EngineeringContext context,
    ReasoningSnapshot arei, {
    List<SmartRegion> regions = const [],
    Map<String, dynamic> facts = const {},
  }) async {
    final result = api.analyze(arei, regions: regions, facts: facts);
    context.history.record(
      projectId: context.projectId,
      entityId: arei.meshId,
      domain: 'engineering_cognition',
      action: 'analyzed',
      snapshot: result.snapshot,
    );
    context.graph.addNode(
      EngineeringGraphNode(arei.meshId, EngineeringNodeType.mesh),
    );
    for (final feature in result.snapshot.features) {
      context.graph.addNode(
        EngineeringGraphNode(
          feature.id,
          EngineeringNodeType.feature,
          metadata: {'kind': feature.kind, 'confidence': feature.confidence},
        ),
      );
      if (!context.graph.edges.any(
        (e) => e.sourceId == arei.meshId && e.targetId == feature.id,
      )) {
        context.graph.connect(
          EngineeringGraphEdge(arei.meshId, feature.id, 'recognizedAs'),
        );
      }
    }
    await context.events.publish(
      EngineeringEvent(
        id: 'cognition:${DateTime.now().microsecondsSinceEpoch}',
        projectId: context.projectId,
        domain: 'engineering_cognition',
        type: 'analysisCompleted',
        entityId: arei.meshId,
        timestamp: DateTime.now().toUtc(),
        payload: {'features': result.snapshot.features.length},
      ),
    );
    return result;
  }
}
