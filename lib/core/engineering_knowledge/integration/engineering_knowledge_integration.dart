import '../../engineering/context/engineering_context.dart';
import '../../engineering/events/engineering_event_bus.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering/learning/engineering_learning.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../api/engineering_knowledge_api.dart';
import '../reasoning/engineering_reasoner.dart';

class EngineeringKnowledgeIntegration {
  const EngineeringKnowledgeIntegration(this.api);
  final EngineeringKnowledgeApi api;
  Future<EngineeringReasoningResult> inferArei(
    EngineeringContext context,
    ReasoningSnapshot snapshot, {
    Map<String, dynamic> observedFacts = const {},
  }) async {
    final cacheKey =
            '${snapshot.meshId}:${snapshot.createdAt.microsecondsSinceEpoch}',
        cached = context.cache.get<EngineeringReasoningResult>(
          'engineering_knowledge',
          cacheKey,
        );
    if (cached != null) return cached;
    final result = api.inferArei(snapshot, observedFacts: observedFacts);
    context.cache.put('engineering_knowledge', cacheKey, result);
    context.history.record(
      projectId: context.projectId,
      entityId: snapshot.meshId,
      domain: 'engineering_knowledge',
      action: 'inferred',
      snapshot: result,
    );
    final nodeId =
        'knowledge:${snapshot.meshId}:${snapshot.createdAt.microsecondsSinceEpoch}';
    context.graph.addNode(
      EngineeringGraphNode(snapshot.meshId, EngineeringNodeType.mesh),
    );
    context.graph.addNode(
      EngineeringGraphNode(
        nodeId,
        EngineeringNodeType.ai,
        metadata: {'inferences': result.inferences.length},
      ),
    );
    if (!context.graph.edges.any(
      (e) => e.sourceId == snapshot.meshId && e.targetId == nodeId,
    )) {
      context.graph.connect(
        EngineeringGraphEdge(snapshot.meshId, nodeId, 'interpretedBy'),
      );
    }
    await context.events.publish(
      EngineeringEvent(
        id: 'knowledge:${DateTime.now().microsecondsSinceEpoch}',
        projectId: context.projectId,
        domain: 'engineering_knowledge',
        type: 'inferenceCompleted',
        entityId: snapshot.meshId,
        timestamp: DateTime.now().toUtc(),
        payload: {'count': result.inferences.length},
      ),
    );
    return result;
  }

  Future<void> learn(
    EngineeringContext context,
    String entityId,
    String assertion,
    bool accepted,
  ) => context.learning.record(
    EngineeringLearningRecord(
      context.projectId,
      entityId,
      'engineering_knowledge',
      accepted ? 'accepted' : 'rejected',
      DateTime.now().toUtc(),
      {'assertion': assertion},
    ),
  );
}
