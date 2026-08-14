import '../engine/engineering_intelligence_engine.dart';
import '../models/intelligence_models.dart';

class EngineeringAdvisor {
  const EngineeringAdvisor(this.engine);
  final EngineeringIntelligenceEngine engine;
  List<EngineeringRecommendation> get current =>
      List.unmodifiable(engine.recommendations.values);
  EngineeringRecommendation? get latest =>
      current.isEmpty ? null : current.last;
  void accept(String id) => engine.decide(id, RecommendationDecision.accepted);
  void reject(String id) => engine.decide(id, RecommendationDecision.rejected);
  void ignore(String id) => engine.decide(id, RecommendationDecision.ignored);
}
