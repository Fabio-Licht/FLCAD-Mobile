import '../morphing/mesh_morph_engine.dart';

class TopologyStrategy {
  const TopologyStrategy(this.operation, this.score, this.reason);
  final MorphOperation operation;
  final double score;
  final String reason;
}

class AdaptiveTopologySolver {
  const AdaptiveTopologySolver();
  List<TopologyStrategy> rank({
    required double noise,
    required double curvature,
    required bool preserveFeatures,
  }) {
    final preserve = preserveFeatures ? .2 : 0.0,
        values = <TopologyStrategy>[
          TopologyStrategy(
            MorphOperation.relax,
            (noise * .5 + curvature * .2 + preserve).clamp(0, 1).toDouble(),
            'Stabilizes irregular topology',
          ),
          TopologyStrategy(
            MorphOperation.smooth,
            (noise * .7 - preserve).clamp(0, 1).toDouble(),
            'Reduces high-frequency noise',
          ),
          TopologyStrategy(
            MorphOperation.curvatureFlow,
            (curvature * .7).clamp(0, 1).toDouble(),
            'Redistributes curvature',
          ),
        ];
    values.sort((a, b) => b.score.compareTo(a.score));
    return values;
  }
}
