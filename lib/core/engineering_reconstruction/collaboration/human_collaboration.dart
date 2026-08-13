import '../../engineering/learning/engineering_learning.dart';
import '../models/reconstruction_intelligence_models.dart';

class ERIHumanCollaboration {
  ERIHumanCollaboration({EngineeringLearning? learning})
    : learning = learning ?? EngineeringLearning();
  final EngineeringLearning learning;
  Future<EngineeringReconstructionPlan> intervene(
    EngineeringReconstructionPlan plan,
    String nodeId,
    ERINodeStatus status, {
    required String actor,
    required String reason,
    String? replacementTitle,
  }) async {
    if (!const [
      ERINodeStatus.accepted,
      ERINodeStatus.rejected,
      ERINodeStatus.deferred,
      ERINodeStatus.replaced,
    ].contains(status)) {
      throw ArgumentError('Human intervention status required');
    }
    if (!plan.nodes.any((n) => n.id == nodeId)) {
      throw StateError('Node $nodeId not found');
    }
    final nodes = plan.nodes
            .map(
              (n) => n.id == nodeId
                  ? n.copyWith(status: status, title: replacementTitle)
                  : n,
            )
            .toList(),
        entry = ERITimelineEntry(
          plan.timeline.length + 1,
          DateTime.now(),
          status.name,
          nodeId,
          actor,
          reason,
          plan.revision + 1,
        );
    await learning.record(
      EngineeringLearningRecord(
        plan.projectId,
        nodeId,
        'eri',
        status.name,
        entry.timestamp,
        {'actor': actor, 'reason': reason, 'replacement': replacementTitle},
      ),
    );
    return plan.copyWith(
      revision: plan.revision + 1,
      nodes: nodes,
      timeline: [...plan.timeline, entry],
    );
  }
}
