import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../reconstruction_strategy/models/reconstruction_strategy_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../analytics/interactive_assistant_analytics.dart';
import '../engine/interactive_engineering_assistant_engine.dart';
import '../models/interactive_assistant_models.dart';

class InteractiveEngineeringAssistantApi {
  const InteractiveEngineeringAssistantApi(this.engine);
  final InteractiveEngineeringAssistantEngine engine;
  InteractiveAssistantSession start({
    required String sessionId,
    required EngineeringFeatureSession features,
    required SmartReferenceSession references,
    required ReconstructionStrategySession strategies,
  }) => engine.start(
    sessionId: sessionId,
    features: features,
    references: references,
    strategies: strategies,
  );
  EngineeringAnswer answer(String sessionId, EngineeringQuestion question) =>
      engine.answer(sessionId, question);
  InteractiveAssistantSession accept(
    String sessionId,
    String suggestionId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    suggestionId: suggestionId,
    type: SuggestionDecisionType.accepted,
    reason: reason,
  );
  InteractiveAssistantSession reject(
    String sessionId,
    String suggestionId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    suggestionId: suggestionId,
    type: SuggestionDecisionType.rejected,
    reason: reason,
  );
  InteractiveAssistantSession completeStep(
    String sessionId,
    String stepId,
    String reason,
  ) => engine.completeStep(sessionId, stepId, reason);
  InteractiveAssistantSession rollback(String id, int snapshotSequence) =>
      engine.rollback(id, snapshotSequence);
  InteractiveAssistantAnalytics analytics(String id) => engine.analytics(id);
  Future<void> persist(String id) => engine.persist(id);
}
