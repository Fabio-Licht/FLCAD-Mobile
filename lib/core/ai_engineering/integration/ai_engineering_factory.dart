import 'dart:io';

import '../api/ai_engineering_api.dart';
import '../confidence/confidence_engine.dart';
import '../engine/ai_engineering_engine.dart';
import '../intent/engineering_intent_engine.dart';
import '../repository/engineering_intent_repository.dart';
import 'ai_engineering_integration.dart';

class AIEngineeringFactory {
  const AIEngineeringFactory();
  AIEngineeringApi create({
    required Directory projectDirectory,
    ConfidenceWeights? weights,
    AIEngineeringIntegration? integration,
  }) {
    final confidence = ConfidenceEngine(weights ?? ConfidenceWeights.equal);
    return AIEngineeringApi(
      AIEngineeringEngine(
        intentEngine: EngineeringIntentEngine(confidenceEngine: confidence),
        repository: EngineeringIntentRepository(projectDirectory),
        integration: integration,
      ),
    );
  }
}
