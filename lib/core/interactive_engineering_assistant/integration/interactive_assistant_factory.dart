import 'dart:io';

import '../api/interactive_assistant_api.dart';
import '../engine/interactive_engineering_assistant_engine.dart';
import '../repository/interactive_assistant_repository.dart';
import 'interactive_assistant_integration.dart';

class InteractiveEngineeringAssistantFactory {
  const InteractiveEngineeringAssistantFactory();
  InteractiveEngineeringAssistantApi create({
    required Directory projectDirectory,
    InteractiveAssistantIntegration? integration,
  }) => InteractiveEngineeringAssistantApi(
    InteractiveEngineeringAssistantEngine(
      repository: InteractiveAssistantRepository(projectDirectory),
      integration: integration,
    ),
  );
}
