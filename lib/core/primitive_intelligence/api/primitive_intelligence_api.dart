import '../../ai_engineering/models/ai_engineering_models.dart';
import '../analytics/primitive_intelligence_analytics.dart';
import '../engine/primitive_intelligence_engine.dart';
import '../models/primitive_intelligence_models.dart';

class PrimitiveIntelligenceApi {
  const PrimitiveIntelligenceApi(this.engine);
  final PrimitiveIntelligenceEngine engine;
  PrimitiveIntelligenceSession analyze({
    required String sessionId,
    required EngineeringContextSnapshot context,
    required Iterable<PrimitiveObservation> primitives,
  }) => engine.analyze(
    sessionId: sessionId,
    context: context,
    primitives: primitives,
  );
  PrimitiveIntelligenceSession accept(
    String sessionId,
    String hypothesisId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    hypothesisId: hypothesisId,
    type: PrimitiveDecisionType.accepted,
    reason: reason,
  );
  PrimitiveIntelligenceSession reject(
    String sessionId,
    String hypothesisId,
    String reason,
  ) => engine.decide(
    sessionId: sessionId,
    hypothesisId: hypothesisId,
    type: PrimitiveDecisionType.rejected,
    reason: reason,
  );
  PrimitiveIntelligenceSession rollback(String sessionId, int count) =>
      engine.rollback(sessionId, count);
  List<PrimitiveRecommendation> recommendations(String id) =>
      engine.recommendations(id);
  PrimitiveIntelligenceAnalytics analytics(String id) => engine.analytics(id);
  Future<void> persist(String id) => engine.persist(id);
}
