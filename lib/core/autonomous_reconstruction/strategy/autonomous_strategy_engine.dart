import '../../engineering_cognition/models/cognition_models.dart';
import '../models/reconstruction_models.dart';

class AutonomousStrategy {
  const AutonomousStrategy(
    this.id,
    this.name,
    this.confidence,
    this.risk,
    this.explanation,
  );
  final String id, name, explanation;
  final double confidence;
  final ReconstructionRisk risk;
}

class AutonomousStrategyEngine {
  const AutonomousStrategyEngine();
  List<AutonomousStrategy> candidates(CognitionSnapshot cognition) {
    final mean = cognition.features.isEmpty
            ? 0.0
            : cognition.features
                      .map((f) => f.confidence)
                      .reduce((a, b) => a + b) /
                  cognition.features.length,
        referenceCoverage = cognition.references.isEmpty
            ? 0.0
            : (cognition.references.length / 5).clamp(0, 1).toDouble(),
        surfaceShare = cognition.surfaces.isEmpty
            ? 0.0
            : (cognition.surfaces
                      .where(
                        (s) =>
                            s.recommendation.contains('patch') ||
                            s.recommendation.contains('nurbs'),
                      )
                      .length /
                  cognition.surfaces.length);
    return [
      AutonomousStrategy(
        'reference-first',
        'Reference First',
        (mean * .55 + referenceCoverage * .45).clamp(0, 1),
        referenceCoverage > .4
            ? ReconstructionRisk.low
            : ReconstructionRisk.medium,
        'Stable references minimize downstream rework.',
      ),
      AutonomousStrategy(
        'feature-first',
        'Feature First',
        (mean * .75 + .1).clamp(0, 1),
        mean > .7 ? ReconstructionRisk.medium : ReconstructionRisk.high,
        'High-confidence parametric features can organize reconstruction.',
      ),
      AutonomousStrategy(
        'surface-first',
        'Surface First',
        (mean * .45 + surfaceShare * .45).clamp(0, 1),
        surfaceShare > .4 ? ReconstructionRisk.medium : ReconstructionRisk.high,
        'Freeform evidence favors early surface planning.',
      ),
    ]..sort((a, b) => _utility(b).compareTo(_utility(a)));
  }

  AutonomousStrategy select(CognitionSnapshot cognition) =>
      candidates(cognition).first;
  double _utility(AutonomousStrategy s) => s.confidence - (s.risk.index * .08);
}
