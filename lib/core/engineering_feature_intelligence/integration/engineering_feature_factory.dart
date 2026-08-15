import 'dart:io';

import '../api/engineering_feature_intelligence_api.dart';
import '../confidence/feature_confidence_engine.dart';
import '../engine/engineering_feature_intelligence_engine.dart';
import '../repository/engineering_feature_repository.dart';
import 'engineering_feature_integration.dart';

class EngineeringFeatureIntelligenceFactory {
  const EngineeringFeatureIntelligenceFactory();
  EngineeringFeatureIntelligenceApi create({
    required Directory projectDirectory,
    FeatureConfidenceWeights? weights,
    EngineeringFeatureIntegration? integration,
  }) => EngineeringFeatureIntelligenceApi(
    EngineeringFeatureIntelligenceEngine(
      repository: EngineeringFeatureRepository(projectDirectory),
      confidence: FeatureConfidenceEngine(
        weights ?? FeatureConfidenceWeights.equal,
      ),
      integration: integration,
    ),
  );
}
