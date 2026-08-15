import '../models/reconstruction_strategy_models.dart';

class ReconstructionRecommendation {
  const ReconstructionRecommendation(this.strategy);
  final ReconstructionStrategy strategy;
  Map<String, dynamic> toJson() => {
    'strategyId': strategy.id,
    'justification': strategy.justification,
    'evidence': strategy.evidence.map((e) => e.toJson()).toList(),
    'referencesUsed':
        strategy.evidence.expand((e) => e.referenceIds).toSet().toList()
          ..sort(),
    'features': strategy.evidence.expand((e) => e.featureIds).toSet().toList()
      ..sort(),
    'primitiveGraph':
        strategy.evidence.expand((e) => e.primitiveIds).toSet().toList()
          ..sort(),
    'featureGraph':
        strategy.evidence.expand((e) => e.featureIds).toSet().toList()..sort(),
    'smartReferences':
        strategy.evidence.expand((e) => e.referenceIds).toSet().toList()
          ..sort(),
    'discardedHypotheses': strategy.reasoning.discardedHypotheses,
    'reasoning': strategy.reasoning.toJson(),
    'consultative': true,
    'commandsExecuted': false,
    'entitiesCreated': false,
    'geometryModified': false,
  };
}

class ReconstructionAdvisor {
  const ReconstructionAdvisor();
  List<ReconstructionRecommendation> advise(
    ReconstructionStrategySession session,
  ) => List.unmodifiable(
    session.strategies.map(ReconstructionRecommendation.new),
  );
}
