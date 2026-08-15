import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../advisor/reconstruction_advisor.dart';
import '../analytics/reconstruction_strategy_analytics.dart';
import '../engine/reconstruction_strategy_engine.dart';
import '../models/reconstruction_strategy_models.dart';

class ReconstructionStrategyApi {
  const ReconstructionStrategyApi(this.engine);
  final ReconstructionStrategyEngine engine;
  ReconstructionStrategySession analyze({
    required String sessionId,
    required EngineeringFeatureSession features,
    required SmartReferenceSession references,
  }) => engine.analyze(
    sessionId: sessionId,
    features: features,
    references: references,
  );
  ReconstructionStrategySession accept(
    String sessionId,
    String strategyId,
    String reason, {
    String? stepId,
  }) => engine.decide(
    sessionId: sessionId,
    strategyId: strategyId,
    stepId: stepId,
    type: StrategyDecisionType.accepted,
    reason: reason,
  );
  ReconstructionStrategySession reject(
    String sessionId,
    String strategyId,
    String reason, {
    String? stepId,
  }) => engine.decide(
    sessionId: sessionId,
    strategyId: strategyId,
    stepId: stepId,
    type: StrategyDecisionType.rejected,
    reason: reason,
  );
  ReconstructionStrategySession editStep({
    required String sessionId,
    required String strategyId,
    required String stepId,
    String? objective,
    String? justification,
    Iterable<String>? prerequisites,
    required String reason,
  }) => engine.editStep(
    sessionId: sessionId,
    strategyId: strategyId,
    stepId: stepId,
    objective: objective,
    justification: justification,
    prerequisites: prerequisites,
    reason: reason,
  );
  ReconstructionStrategySession rollback(String id, int count) =>
      engine.rollback(id, count);
  List<ReconstructionRecommendation> recommendations(String id) =>
      engine.recommendations(id);
  ReconstructionStrategyAnalytics analytics(String id) => engine.analytics(id);
  Future<void> persist(String id) => engine.persist(id);
}
