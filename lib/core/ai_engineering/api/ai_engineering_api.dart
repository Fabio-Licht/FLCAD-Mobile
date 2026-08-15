import '../analytics/ai_engineering_analytics.dart';
import '../context/engineering_context.dart';
import '../engine/ai_engineering_engine.dart';
import '../models/ai_engineering_models.dart';

class AIEngineeringApi {
  const AIEngineeringApi(this.engine);
  final AIEngineeringEngine engine;
  IntentSession start({
    required String sessionId,
    required EngineeringContext context,
    required Iterable<EngineeringIntentType> requestedIntents,
  }) => engine.start(
    sessionId: sessionId,
    context: context,
    requestedIntents: requestedIntents,
  );
  IntentSession accept(String sessionId, String candidateId, String reason) =>
      engine.decide(
        sessionId: sessionId,
        candidateId: candidateId,
        decision: IntentDecisionType.accepted,
        reason: reason,
      );
  IntentSession reject(String sessionId, String candidateId, String reason) =>
      engine.decide(
        sessionId: sessionId,
        candidateId: candidateId,
        decision: IntentDecisionType.rejected,
        reason: reason,
      );
  IntentSession complete(String id) => engine.complete(id);
  IntentSession rollback(String id, int decisionCount) =>
      engine.rollback(id, decisionCount);
  List<AIRecommendation> recommendations(String id) =>
      engine.recommendations(id);
  AIEngineeringAnalytics analytics(String id) => engine.analytics(id);
  Future<void> persist(String id) => engine.persist(id);
}
