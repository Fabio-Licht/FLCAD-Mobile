import '../models/decision_models.dart';

class DecisionSimulator {
  const DecisionSimulator();
  DecisionSimulationResult simulate(
    EngineeringDecision decision,
    DecisionAlternative alternative, {
    Iterable<String> impacted = const [],
  }) => DecisionSimulationResult(
    decisionId: decision.id,
    alternativeId: alternative.id,
    projectedScore: alternative.score,
    projectedCost: alternative.complexity,
    projectedRisk: alternative.risk,
    impact:
        'Contrafactual: ${alternative.name}; nenhuma alteração foi executada.',
    changedDecisionIds: List.unmodifiable(impacted),
  );
}
