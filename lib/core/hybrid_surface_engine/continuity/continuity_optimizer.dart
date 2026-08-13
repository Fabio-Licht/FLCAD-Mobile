import '../../adaptive_surface/continuity/surface_continuity.dart';
import '../models/hybrid_surface_models.dart';

class HybridContinuityOptimizer {
  const HybridContinuityOptimizer();
  ContinuityOptimization evaluate(SharedSurfaceBoundary boundary) {
    final order = switch (boundary.continuity) {
          SurfaceContinuityLevel.g0 => 0,
          SurfaceContinuityLevel.g1 => 1,
          SurfaceContinuityLevel.g2 => 2,
          SurfaceContinuityLevel.g3 => 3,
          _ => 3,
        },
        difficulty = ((order + 1) * .2 + (1 - boundary.confidence) * .4)
            .clamp(0, 1)
            .toDouble(),
        cost = (difficulty * .8).clamp(0, 1).toDouble(),
        robustness = (boundary.confidence * (1 - difficulty * .3))
            .clamp(0, 1)
            .toDouble(),
        impact = ((order + 1) * .2).clamp(0, 1).toDouble();
    return ContinuityOptimization(
      boundaryId: boundary.id,
      level: boundary.continuity,
      difficulty: difficulty,
      cost: cost,
      robustness: robustness,
      impact: impact,
    );
  }
}
