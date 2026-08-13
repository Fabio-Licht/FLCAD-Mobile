import '../intent/surface_intent_engine.dart';
import '../models/adaptive_surface.dart';

class SurfaceQualityEngine {
  const SurfaceQualityEngine();
  SurfaceScore score(SurfaceMetrics m, SurfaceIntent intent) {
    final accuracy = 1 / (1 + m.rmsError),
        continuity = m.continuity.clamp(0, 1).toDouble(),
        curvature = 1 / (1 + m.averageCurvature.abs()),
        production = (accuracy * .7 + curvature * .3),
        aesthetics = (continuity * .7 + curvature * .3),
        machinability = (accuracy * .6 + production * .4),
        total =
            (accuracy * (intent.weights['accuracy'] ?? .34) +
                    continuity * (intent.weights['continuity'] ?? .33) +
                    production * (intent.weights['manufacturing'] ?? .33))
                .clamp(0, 1)
                .toDouble();
    return SurfaceScore(
      accuracy: accuracy,
      continuity: continuity,
      curvature: curvature,
      production: production,
      aesthetics: aesthetics,
      machinability: machinability,
      total: total,
    );
  }
}
