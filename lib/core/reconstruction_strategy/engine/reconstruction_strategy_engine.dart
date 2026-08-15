import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../advisor/reconstruction_advisor.dart';
import '../analytics/reconstruction_strategy_analytics.dart';
import '../integration/reconstruction_strategy_integration.dart';
import '../models/reconstruction_strategy_models.dart';
import '../planning/reconstruction_planning_engines.dart';
import '../playbook/engineering_playbook_builder.dart';
import '../repository/reconstruction_strategy_repository.dart';

class ReconstructionStrategyEngine {
  ReconstructionStrategyEngine({
    required this.repository,
    this.planner = const MultiStrategyPlanner(),
    this.playbookBuilder = const EngineeringPlaybookBuilder(),
    this.difficultyEstimator = const ReconstructionDifficultyEstimator(),
    this.scheduler = const DependencyScheduler(),
    this.advisor = const ReconstructionAdvisor(),
    this.integration,
  });
  final ReconstructionStrategyRepository repository;
  final MultiStrategyPlanner planner;
  final EngineeringPlaybookBuilder playbookBuilder;
  final ReconstructionDifficultyEstimator difficultyEstimator;
  final DependencyScheduler scheduler;
  final ReconstructionAdvisor advisor;
  final ReconstructionStrategyIntegration? integration;
  ReconstructionStrategySession analyze({
    required String sessionId,
    required EngineeringFeatureSession features,
    required SmartReferenceSession references,
  }) {
    if (features.context.projectId != references.context.projectId) {
      throw StateError(
        'Feature and Smart Reference contexts belong to different projects',
      );
    }
    final strategies = planner.plan(sessionId, features, references);
    final playbook = playbookBuilder.build(
      sessionId,
      strategies,
      features.dna.predominantFeatures.join('+'),
    );
    final difficulty = difficultyEstimator.estimate(
      features,
      references,
      playbook.steps.length,
    );
    final session = ReconstructionStrategySession(
      id: sessionId,
      context: features.context,
      strategies: strategies,
      playbook: playbook,
      difficulty: difficulty,
      decisions: const [],
    );
    repository.add(session);
    integration?.onSessionChanged(session);
    return session;
  }

  ReconstructionStrategySession decide({
    required String sessionId,
    required String strategyId,
    String? stepId,
    required StrategyDecisionType type,
    required String reason,
  }) {
    final current = _require(sessionId);
    final strategy = current.strategies
        .where((e) => e.id == strategyId)
        .firstOrNull;
    if (strategy == null) {
      throw StateError('Unknown reconstruction strategy: $strategyId');
    }
    if (stepId != null && !strategy.steps.any((e) => e.id == stepId)) {
      throw StateError('Unknown reconstruction step: $stepId');
    }
    final updated = current.copyWith(
      decisions: [
        ...current.decisions,
        StrategyDecision(
          strategyId: strategyId,
          type: type,
          reason: reason,
          sequence: current.decisions.length,
          stepId: stepId,
        ),
      ],
    );
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  ReconstructionStrategySession editStep({
    required String sessionId,
    required String strategyId,
    required String stepId,
    String? objective,
    String? justification,
    Iterable<String>? prerequisites,
    required String reason,
  }) {
    final current = _require(sessionId);
    final strategy = current.strategies
        .where((e) => e.id == strategyId)
        .firstOrNull;
    if (strategy == null) {
      throw StateError('Unknown reconstruction strategy: $strategyId');
    }
    final original = strategy.steps.where((e) => e.id == stepId).firstOrNull;
    if (original == null) {
      throw StateError('Unknown reconstruction step: $stepId');
    }
    final edited = original.edit(
      objective: objective,
      justification: justification,
      prerequisites: prerequisites,
    );
    final steps = [
      for (final step in strategy.steps) step.id == stepId ? edited : step,
    ];
    final updatedStrategy = strategy.replaceStep(
      edited,
      scheduler.schedule(steps),
    );
    final updated = current.copyWith(
      strategies: [
        for (final item in current.strategies)
          item.id == strategyId ? updatedStrategy : item,
      ],
      playbook: current.playbook.recommendedStrategyId == strategyId
          ? current.playbook.replaceStep(edited)
          : current.playbook,
      decisions: [
        ...current.decisions,
        StrategyDecision(
          strategyId: strategyId,
          type: StrategyDecisionType.edited,
          reason: reason,
          sequence: current.decisions.length,
          stepId: stepId,
        ),
      ],
    );
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  ReconstructionStrategySession rollback(String id, int count) {
    final value = repository.rollback(id, count);
    integration?.onSessionChanged(value);
    return value;
  }

  List<ReconstructionRecommendation> recommendations(String id) =>
      advisor.advise(_require(id));
  ReconstructionStrategyAnalytics analytics(String id) =>
      ReconstructionStrategyAnalytics.fromSession(_require(id));
  Future<void> persist(String id) => repository.persist(
    id,
    recommendations: recommendations(id),
    analytics: analytics(id),
  );
  ReconstructionStrategySession _require(String id) {
    final value = repository.find(id);
    if (value == null) {
      throw StateError('Unknown reconstruction strategy session: $id');
    }
    return value;
  }
}
