import 'dart:io';

import '../api/reconstruction_strategy_api.dart';
import '../engine/reconstruction_strategy_engine.dart';
import '../planning/reconstruction_planning_engines.dart';
import '../repository/reconstruction_strategy_repository.dart';
import 'reconstruction_strategy_integration.dart';

class ReconstructionStrategyFactory {
  const ReconstructionStrategyFactory();
  ReconstructionStrategyApi create({
    required Directory projectDirectory,
    ReconstructionDifficultyPolicy difficultyPolicy =
        const ReconstructionDifficultyPolicy(),
    ReconstructionStrategyIntegration? integration,
  }) => ReconstructionStrategyApi(
    ReconstructionStrategyEngine(
      repository: ReconstructionStrategyRepository(projectDirectory),
      difficultyEstimator: ReconstructionDifficultyEstimator(
        policy: difficultyPolicy,
      ),
      integration: integration,
    ),
  );
}
