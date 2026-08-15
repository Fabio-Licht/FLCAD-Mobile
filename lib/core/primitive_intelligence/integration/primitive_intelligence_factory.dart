import 'dart:io';

import '../api/primitive_intelligence_api.dart';
import '../classification/primitive_classification_engine.dart';
import '../engine/primitive_intelligence_engine.dart';
import '../ranking/primitive_ranking_engine.dart';
import '../repository/primitive_intelligence_repository.dart';
import 'primitive_intelligence_integration.dart';

class PrimitiveIntelligenceFactory {
  const PrimitiveIntelligenceFactory();
  PrimitiveIntelligenceApi create({
    required Directory projectDirectory,
    PrimitiveRankingWeights? rankingWeights,
    PrimitiveClassificationPolicy classificationPolicy =
        const PrimitiveClassificationPolicy(),
    PrimitiveIntelligenceIntegration? integration,
  }) => PrimitiveIntelligenceApi(
    PrimitiveIntelligenceEngine(
      repository: PrimitiveIntelligenceRepository(projectDirectory),
      ranking: PrimitiveRankingEngine(
        rankingWeights ?? PrimitiveRankingWeights.equal,
      ),
      classification: PrimitiveClassificationEngine(
        policy: classificationPolicy,
      ),
      integration: integration,
    ),
  );
}
