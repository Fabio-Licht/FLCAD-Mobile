import '../models/hybrid_surface_models.dart';

class SurfaceQualityPredictor {
  const SurfaceQualityPredictor();
  SurfaceQualityPrediction predict(HybridStrategy strategy, int boundaryCount) {
    final expectedError = ((1 - strategy.quality) * .1 + boundaryCount * .002)
            .clamp(0, 1)
            .toDouble(),
        continuity = (strategy.robustness * .6 + strategy.quality * .4)
            .clamp(0, 1)
            .toDouble(),
        minutes = (strategy.cost * 180 + strategy.surfaceIds.length * 12)
            .round();
    return SurfaceQualityPrediction(
      strategyId: strategy.id,
      expectedError: expectedError,
      stability: strategy.robustness,
      continuity: continuity,
      editability: strategy.editability,
      reuse: strategy.maintainability,
      reconstructionTime: Duration(minutes: minutes),
    );
  }
}
