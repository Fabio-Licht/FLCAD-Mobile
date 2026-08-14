import '../engine/engineering_intelligence_engine.dart';
import '../models/intelligence_models.dart';

class EngineeringAnalysisBuilder {
  const EngineeringAnalysisBuilder(this.engine);
  final EngineeringIntelligenceEngine engine;
  Future<EngineeringAnalysis> build(
    IntelligenceAnalysisType type,
    ProjectKnowledgeSnapshot snapshot,
  ) => engine.analyze(type, snapshot);
}
