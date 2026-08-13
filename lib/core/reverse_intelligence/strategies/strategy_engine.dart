import '../models/intelligence_models.dart';

class StrategyEngine {
  const StrategyEngine();
  List<ReconstructionStrategy> generate(
    ReconstructionPlan base,
    List<ProbabilityScore> classifications,
    List<ProbabilityScore> manufacturing,
  ) {
    final dominant = classifications.first,
        process = manufacturing.first,
        evidence = [...dominant.evidence, ...process.evidence];
    return [
      ReconstructionStrategy(
        'reference-first',
        'Reference First',
        base,
        (dominant.probability * .65 + process.probability * .35).clamp(0, 1),
        .45,
        evidence,
      ),
      ReconstructionStrategy(
        'region-first',
        'Region First',
        base,
        (dominant.probability * .55 + .25).clamp(0, 1),
        .35,
        dominant.evidence,
      ),
      ReconstructionStrategy(
        'validation-first',
        'Validation First',
        base,
        (dominant.probability * .45 + .35).clamp(0, 1),
        .65,
        evidence,
      ),
    ];
  }

  StrategyDecision select(List<ReconstructionStrategy> candidates) {
    if (candidates.isEmpty) throw ArgumentError('Strategies required');
    final ranked = [...candidates]
      ..sort((a, b) => _utility(b).compareTo(_utility(a)));
    final selected = ranked.first,
        runner = ranked.length > 1 ? ranked[1] : selected,
        margin = (_utility(selected) - _utility(runner)).abs();
    return StrategyDecision(
      selected,
      List.unmodifiable(ranked),
      'Selected ${selected.name}: evidence confidence ${selected.expectedConfidence.toStringAsFixed(3)}, normalized execution cost ${selected.cost.toStringAsFixed(3)}, utility ${_utility(selected).toStringAsFixed(3)}.',
      (selected.expectedConfidence * (.8 + .2 * margin)).clamp(0, 1),
    );
  }

  double _utility(ReconstructionStrategy s) =>
      s.expectedConfidence * .75 + (1 - s.cost) * .25;
}
