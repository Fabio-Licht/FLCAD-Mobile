import '../models/hybrid_surface_models.dart';

class HybridSurfaceStatistics {
  const HybridSurfaceStatistics({
    required this.surfaceCount,
    required this.hybridRegionCount,
    required this.averageContinuity,
    required this.averageScore,
    required this.predictedCost,
    required this.predictedGain,
    required this.predictedTime,
  });
  final int surfaceCount, hybridRegionCount;
  final double averageContinuity, averageScore, predictedCost, predictedGain;
  final Duration predictedTime;
}

class HybridSurfaceAnalytics {
  const HybridSurfaceAnalytics();
  HybridSurfaceStatistics calculate(
    HybridSurfacePlan plan,
    List<SurfaceQualityPrediction> quality,
  ) {
    final score = plan.strategies.isEmpty
            ? 0.0
            : plan.strategies
                      .map((e) => e.score)
                      .fold<double>(0, (a, b) => a + b) /
                  plan.strategies.length,
        continuity = plan.continuity.isEmpty
            ? 0.0
            : plan.continuity
                      .map((e) => e.robustness)
                      .fold<double>(0, (a, b) => a + b) /
                  plan.continuity.length,
        cost = plan.strategies.isEmpty ? 0.0 : plan.strategies.first.cost,
        time = quality.isEmpty
            ? Duration.zero
            : quality.first.reconstructionTime;
    return HybridSurfaceStatistics(
      surfaceCount: plan.nodes.length,
      hybridRegionCount: plan.regions.length,
      averageContinuity: continuity,
      averageScore: score,
      predictedCost: cost,
      predictedGain: (1 - cost) * score,
      predictedTime: time,
    );
  }
}
