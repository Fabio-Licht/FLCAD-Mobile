import '../../reconstruction_strategy/models/reconstruction_strategy_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../models/interactive_assistant_models.dart';

class ReconstructionProgressAssistant {
  const ReconstructionProgressAssistant();
  List<ReconstructionProgressItem> build(
    ReconstructionStrategySession session,
  ) {
    final strategy = session.strategies.first;
    final completed = session.decisions
        .where(
          (e) => e.type == StrategyDecisionType.accepted && e.stepId != null,
        )
        .map((e) => e.stepId)
        .toSet();
    var currentAssigned = false;
    return List.unmodifiable(
      strategy.steps.map((step) {
        final state = completed.contains(step.id)
            ? ProgressState.completed
            : !currentAssigned
            ? ProgressState.inProgress
            : ProgressState.pending;
        if (state == ProgressState.inProgress) {
          currentAssigned = true;
        }
        return ReconstructionProgressItem(
          stepId: step.id,
          objective: step.objective,
          state: state,
          order: step.order,
        );
      }),
    );
  }
}

class EngineeringAlertEngine {
  const EngineeringAlertEngine();
  List<EngineeringAlert> build(
    String sessionId,
    SmartReferenceSession references,
    ReconstructionStrategySession strategies,
    List<AssistantEvidence> evidence,
  ) {
    final alerts = <EngineeringAlert>[];
    if (strategies.strategies.length > 1) {
      alerts.add(
        EngineeringAlert(
          id: '$sessionId:alert:alternatives',
          severity: AlertSeverity.information,
          message:
              '${strategies.strategies.length - 1} alternative strategies are available.',
          justification:
              'Multi-strategy planning produced auditable alternatives.',
          evidence: evidence,
        ),
      );
    }
    if (!references.candidates.any(
      (e) => e.category == ReferenceCategory.coordinateSystem,
    )) {
      alerts.add(
        EngineeringAlert(
          id: '$sessionId:alert:coordinate',
          severity: AlertSeverity.warning,
          message: 'No coordinate system candidate is available.',
          justification:
              'Smart References contains no coordinate-system candidate.',
          evidence: evidence,
        ),
      );
    }
    if (references.candidates.any(
      (e) => !strategies.strategies.first.evidence.any(
        (item) => item.referenceIds.contains(e.id),
      ),
    )) {
      alerts.add(
        EngineeringAlert(
          id: '$sessionId:alert:unused',
          severity: AlertSeverity.information,
          message: 'There are unused Smart References.',
          justification:
              'At least one ranked reference is absent from the active strategy evidence.',
          evidence: evidence,
        ),
      );
    }
    return List.unmodifiable(alerts);
  }
}

class EngineeringSuggestionEngine {
  const EngineeringSuggestionEngine();
  List<EngineeringSuggestion> build(
    String sessionId,
    SmartReferenceSession references,
    ReconstructionStrategySession strategies,
    List<ReconstructionProgressItem> progress,
    List<AssistantEvidence> evidence,
  ) {
    final next = progress
        .where((e) => e.state == ProgressState.inProgress)
        .firstOrNull;
    final critical = strategies.difficulty.criticalRegions;
    return List.unmodifiable([
      if (next != null)
        EngineeringSuggestion(
          id: '$sessionId:suggestion:next',
          action: next.objective,
          justification:
              'This is the first incomplete dependency-scheduled Playbook step.',
          confidence: strategies.strategies.first.confidence,
          evidence: evidence,
        ),
      EngineeringSuggestion(
        id: '$sessionId:suggestion:reference',
        action: 'Review ${references.candidates.first.type.name}',
        justification: 'This is the highest-ranked Smart Reference candidate.',
        confidence: references.candidates.first.scores.overallConfidence,
        evidence: evidence,
      ),
      if (strategies.strategies.length > 1)
        EngineeringSuggestion(
          id: '$sessionId:suggestion:alternative',
          action: 'Compare ${strategies.strategies[1].name}',
          justification:
              'An alternative complete strategy is available for side-by-side review.',
          confidence: strategies.strategies[1].confidence,
          evidence: evidence,
        ),
      if (critical.isNotEmpty)
        EngineeringSuggestion(
          id: '$sessionId:suggestion:critical',
          action: 'Review critical regions',
          justification:
              'Difficulty analysis identified ${critical.length} confidence-critical regions.',
          confidence: strategies.strategies.first.confidence,
          evidence: evidence,
        ),
    ]);
  }
}

class MultiStrategyComparator {
  const MultiStrategyComparator();
  List<StrategyComparison> compare(ReconstructionStrategySession session) =>
      List.unmodifiable(
        session.strategies.map(
          (strategy) => StrategyComparison(
            strategyId: strategy.id,
            name: strategy.name,
            precision: strategy.confidence,
            estimatedMinutes: strategy.estimatedDuration.inMinutes,
            complexity: strategy.complexity,
            confidence: strategy.confidence,
          ),
        ),
      );
}
