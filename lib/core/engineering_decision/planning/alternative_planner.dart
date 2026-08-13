import '../models/decision_models.dart';

class AlternativePlanner {
  const AlternativePlanner();
  List<DecisionAlternative> plan(DecisionScore score) => [
    DecisionAlternative(
      id: 'primary',
      name: 'Estratégia principal',
      kind: 'primary',
      estimatedTime: const Duration(minutes: 4),
      confidence: score.value,
      complexity: .55,
      risk: _risk(1 - score.value),
      score: score.value,
    ),
    DecisionAlternative(
      id: 'alternative',
      name: 'Estratégia alternativa',
      kind: 'alternative',
      estimatedTime: const Duration(minutes: 6),
      confidence: (score.value * .92).clamp(0, 1),
      complexity: .7,
      risk: DecisionRisk.medium,
      score: score.value * .86,
    ),
    DecisionAlternative(
      id: 'conservative',
      name: 'Estratégia conservadora',
      kind: 'conservative',
      estimatedTime: const Duration(minutes: 9),
      confidence: (score.value + .05).clamp(0, 1),
      complexity: .35,
      risk: DecisionRisk.low,
      score: score.value * .9,
    ),
  ];
  DecisionRisk _risk(double value) => value < .15
      ? DecisionRisk.low
      : value < .3
      ? DecisionRisk.medium
      : value < .5
      ? DecisionRisk.high
      : DecisionRisk.critical;
}
