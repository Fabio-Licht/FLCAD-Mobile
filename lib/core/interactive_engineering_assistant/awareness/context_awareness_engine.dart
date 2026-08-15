import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../reconstruction_strategy/models/reconstruction_strategy_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../models/interactive_assistant_models.dart';

class ContextAwarenessEngine {
  const ContextAwarenessEngine();
  AssistantContext build({
    required EngineeringFeatureSession features,
    required SmartReferenceSession references,
    required ReconstructionStrategySession strategies,
    required Iterable<String> sessionHistory,
  }) {
    final active = strategies.strategies.first;
    final completed = strategies.decisions
        .where(
          (e) => e.type == StrategyDecisionType.accepted && e.stepId != null,
        )
        .map((e) => e.stepId)
        .toSet();
    final current = active.steps
        .where((e) => !completed.contains(e.id))
        .firstOrNull;
    final values = features.context.values;
    final user = values['userContext'] as Map<String, dynamic>? ?? const {};
    final objectives = (user['objectives'] as List<dynamic>? ?? const []).map(
      (e) => e.toString(),
    );
    return AssistantContext(
      projectId: features.context.projectId,
      activePartId: features.context.activePartId,
      loadedPart: features.context.activePartId,
      primitiveCount: features.hypotheses
          .expand((e) => e.evidence.expand((item) => item.primitiveIds))
          .toSet()
          .length,
      featureCount: features.hypotheses.length,
      referenceCount: references.candidates.length,
      activePlaybookId: strategies.playbook.id,
      activeStrategyId: active.id,
      currentStepId: current?.id,
      projectObjectives: objectives,
      sessionHistory: sessionHistory,
    );
  }
}
