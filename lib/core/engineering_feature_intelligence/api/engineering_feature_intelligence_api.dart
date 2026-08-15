import '../../primitive_intelligence/models/primitive_intelligence_models.dart';
import '../advisor/engineering_feature_advisor.dart';
import '../analytics/engineering_feature_analytics.dart';
import '../engine/engineering_feature_intelligence_engine.dart';
import '../models/engineering_feature_models.dart';

class EngineeringFeatureIntelligenceApi {
  const EngineeringFeatureIntelligenceApi(this.engine);
  final EngineeringFeatureIntelligenceEngine engine;
  EngineeringFeatureSession analyze({
    required String sessionId,
    required PrimitiveIntelligenceSession primitives,
  }) => engine.analyze(sessionId: sessionId, primitives: primitives);
  EngineeringFeatureSession accept(
    String sessionId,
    String hypothesisId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    hypothesisId: hypothesisId,
    type: FeatureDecisionType.accepted,
    reason: reason,
  );
  EngineeringFeatureSession reject(
    String sessionId,
    String hypothesisId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    hypothesisId: hypothesisId,
    type: FeatureDecisionType.rejected,
    reason: reason,
  );
  EngineeringFeatureSession rollback(String sessionId, int count) =>
      engine.rollback(sessionId, count);
  List<EngineeringFeatureRecommendation> recommendations(String id) =>
      engine.recommendations(id);
  EngineeringFeatureAnalytics analytics(String id) => engine.analytics(id);
  Future<void> persist(String id) => engine.persist(id);
}
