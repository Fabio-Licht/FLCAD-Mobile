import '../models/adaptive_surface.dart';
import '../network/surface_network.dart';

class GlobalOptimizationResult {
  const GlobalOptimizationResult(
    this.network,
    this.initialScore,
    this.finalScore,
    this.iterations,
  );
  final SurfaceNetwork network;
  final double initialScore, finalScore;
  final int iterations;
}

class GlobalSurfaceOptimizer {
  const GlobalSurfaceOptimizer();
  Future<GlobalOptimizationResult> optimize(
    SurfaceNetwork network, {
    int iterations = 3,
  }) async {
    if (network.surfaces.isEmpty) {
      return GlobalOptimizationResult(network, 0, 0, 0);
    }
    final initial =
        network.surfaces.values
            .map((s) => s.score.total)
            .reduce((a, b) => a + b) /
        network.surfaces.length;
    var updated = network;
    for (var i = 0; i < iterations; i++) {
      final values = <String, AdaptiveSurface>{};
      for (final surface in updated.surfaces.values) {
        final neighbors = updated.neighbors(surface.id);
        if (neighbors.isEmpty) {
          values[surface.id] = surface;
          continue;
        }
        final target =
                (surface.metrics.continuity +
                    neighbors
                        .map((n) => n.metrics.continuity)
                        .reduce((a, b) => a + b)) /
                (neighbors.length + 1),
            metrics = SurfaceMetrics(
              rmsError: surface.metrics.rmsError,
              maxError: surface.metrics.maxError,
              meanError: surface.metrics.meanError,
              averageCurvature: surface.metrics.averageCurvature,
              continuity: target,
              confidence: surface.metrics.confidence,
              pointCount: surface.metrics.pointCount,
            );
        values[surface.id] = surface.copyWith(metrics: metrics);
      }
      updated = SurfaceNetwork(
        surfaces: values,
        constraints: updated.constraints,
      );
    }
    final finalScore =
        updated.surfaces.values
            .map((s) => s.score.total)
            .reduce((a, b) => a + b) /
        updated.surfaces.length;
    return GlobalOptimizationResult(updated, initial, finalScore, iterations);
  }
}
