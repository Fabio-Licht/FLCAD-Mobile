import '../../adaptive_surface/models/surface_geometry.dart';
import '../models/surface_models.dart';

class SurfaceStrategyEngine {
  const SurfaceStrategyEngine();

  List<SurfaceStrategy> compare(List<SurfaceCandidate> candidates) {
    final values = candidates.map((candidate) {
      final analytical = {
        SurfaceKind.plane,
        SurfaceKind.cylinder,
        SurfaceKind.cone,
        SurfaceKind.sphere,
        SurfaceKind.torus,
      }.contains(candidate.kind);
      final double cost = analytical
          ? 0.15
          : switch (candidate.kind) {
              SurfaceKind.nurbs => 0.85,
              SurfaceKind.loft || SurfaceKind.sweep => 0.6,
              _ => 0.5,
            };
      final robustness = analytical ? 0.95 : candidate.confidence * 0.8;
      final maintainability = analytical ? 0.95 : 1 - cost * 0.6;
      final score =
          (candidate.confidence * 0.3 +
                  candidate.quality * 0.2 +
                  candidate.coverage * 0.15 +
                  robustness * 0.15 +
                  maintainability * 0.1 +
                  (1 - cost) * 0.1)
              .clamp(0, 1)
              .toDouble();
      return SurfaceStrategy(
        id: 'strategy-${candidate.id}',
        candidateId: candidate.id,
        score: score,
        cost: cost,
        robustness: robustness,
        maintainability: maintainability,
        predictedQuality: candidate.quality,
        explanation: analytical
            ? 'Analytical surface preferred for robustness, maintenance and low cost'
            : 'Procedural/freeform strategy retained where analytical evidence is insufficient',
      );
    }).toList();
    values.sort((a, b) => b.score.compareTo(a.score));
    return values;
  }
}
