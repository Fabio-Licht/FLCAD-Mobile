import '../advisor/engineering_advisor.dart';
import '../builders/analysis_builder.dart';
import '../engine/engineering_intelligence_engine.dart';
import '../models/intelligence_models.dart';

class EngineeringIntelligenceApi {
  EngineeringIntelligenceApi(this.engine)
    : builder = EngineeringAnalysisBuilder(engine),
      advisor = EngineeringAdvisor(engine);
  final EngineeringIntelligenceEngine engine;
  final EngineeringAnalysisBuilder builder;
  final EngineeringAdvisor advisor;
  EngineeringScore? get score => engine.currentScore;
  List<EngineeringRecommendation> get recommendations =>
      List.unmodifiable(engine.recommendations.values);
  List<EngineeringDiagnostic> get diagnostics =>
      List.unmodifiable(engine.diagnostics.values);
  Future<EngineeringAnalysis> analyzeProject(
    ProjectKnowledgeSnapshot snapshot,
  ) => engine.analyzeProject(snapshot);
}
