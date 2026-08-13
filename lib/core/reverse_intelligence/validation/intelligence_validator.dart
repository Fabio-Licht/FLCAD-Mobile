import '../models/intelligence_models.dart';

class IntelligenceValidator {
  const IntelligenceValidator({this.minimumDecisionConfidence = .45});
  final double minimumDecisionConfidence;
  ValidationAssessment validate(
    MeshObservation observation,
    StrategyDecision decision,
  ) {
    final findings = <String>[];
    if (observation.boundaryEdgeCount > 0) {
      findings.add(
        '${observation.boundaryEdgeCount} boundary edges reduce topology certainty',
      );
    }
    if (decision.confidence < minimumDecisionConfidence) {
      findings.add(
        'Decision confidence below ${minimumDecisionConfidence.toStringAsFixed(2)}',
      );
    }
    if (observation.surfaceArea <= 0) {
      findings.add('Surface area is degenerate');
    }
    final score =
        (decision.confidence *
                (observation.surfaceArea > 0 ? 1 : .0) *
                (observation.isWatertight ? 1 : .85))
            .clamp(0, 1)
            .toDouble();
    return ValidationAssessment(
      score >= minimumDecisionConfidence && observation.surfaceArea > 0,
      score,
      findings,
    );
  }
}
