import '../models/adaptive_surface.dart';

enum SurfaceRepairAction {
  smoothNoise,
  removeOscillation,
  fillHole,
  relaxDiscontinuity,
}

class SurfaceRepairEngine {
  const SurfaceRepairEngine();
  AdaptiveSurface repair(
    AdaptiveSurface source,
    Set<SurfaceRepairAction> actions,
  ) {
    var rms = source.metrics.rmsError,
        max = source.metrics.maxError,
        continuity = source.metrics.continuity;
    if (actions.contains(SurfaceRepairAction.smoothNoise)) {
      rms *= .9;
      max *= .92;
    }
    if (actions.contains(SurfaceRepairAction.removeOscillation)) {
      rms *= .95;
    }
    if (actions.contains(SurfaceRepairAction.fillHole) ||
        actions.contains(SurfaceRepairAction.relaxDiscontinuity)) {
      continuity = (continuity + .1).clamp(0, 1);
    }
    return source.copyWith(
      metrics: SurfaceMetrics(
        rmsError: rms,
        maxError: max,
        meanError: source.metrics.meanError,
        averageCurvature: source.metrics.averageCurvature,
        continuity: continuity,
        confidence: source.metrics.confidence,
        pointCount: source.metrics.pointCount,
      ),
      status: SurfaceStatus.valid,
      version: source.version + 1,
      updatedAt: DateTime.now(),
    );
  }
}
