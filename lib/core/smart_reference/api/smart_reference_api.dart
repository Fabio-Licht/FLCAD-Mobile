import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../advisor/reference_strategy_advisor.dart';
import '../analytics/smart_reference_analytics.dart';
import '../engine/smart_reference_engine.dart';
import '../models/smart_reference_models.dart';

class SmartReferenceApi {
  const SmartReferenceApi(this.engine);
  final SmartReferenceEngine engine;
  SmartReferenceSession analyze({
    required String sessionId,
    required EngineeringFeatureSession features,
  }) => engine.analyze(sessionId: sessionId, features: features);
  SmartReferenceSession accept(
    String sessionId,
    String referenceId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    referenceId: referenceId,
    type: ReferenceDecisionType.accepted,
    reason: reason,
  );
  SmartReferenceSession reject(
    String sessionId,
    String referenceId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    referenceId: referenceId,
    type: ReferenceDecisionType.rejected,
    reason: reason,
  );
  SmartReferenceSession rollback(String sessionId, int count) =>
      engine.rollback(sessionId, count);
  List<ReferenceRecommendation> recommendations(String id) =>
      engine.recommendations(id);
  SmartReferenceAnalytics analytics(String id) => engine.analytics(id);
  Future<void> persist(String id) => engine.persist(id);
}
