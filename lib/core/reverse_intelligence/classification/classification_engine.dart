import '../models/intelligence_models.dart';

class GeometryClassificationEngine {
  const GeometryClassificationEngine();
  List<ProbabilityScore> classify(MeshObservation o) {
    final sorted = [o.axisExtents.x, o.axisExtents.y, o.axisExtents.z]..sort(),
        flatness = sorted.last == 0 ? 0.0 : 1 - sorted.first / sorted.last,
        elongation = sorted.last == 0 ? 0.0 : 1 - sorted[1] / sorted.last,
        closure = o.isWatertight
            ? 1.0
            : (1 - o.boundaryEdgeCount / (o.triangleCount * 3))
                  .clamp(0, 1)
                  .toDouble();
    Evidence e(String id, String text, double value) => Evidence(
      id: id,
      description: text,
      value: value,
      source: 'classification.features',
    );
    final flat = e('flatness', 'Relative thinness', flatness),
        long = e('elongation', 'Dominant-axis elongation', elongation),
        normal = e('normal_coherence', 'Normal coherence', o.normalCoherence),
        closed = e('closure', 'Topological closure', closure);
    final scores = [
      ProbabilityScore(
        'prismatic',
        (.45 * flatness + .35 * o.normalCoherence + .20 * closure).clamp(0, 1),
        [flat, normal, closed],
      ),
      ProbabilityScore(
        'turned',
        (.55 * elongation + .25 * closure + .20 * (1 - o.normalCoherence))
            .clamp(0, 1),
        [long, closed, normal],
      ),
      ProbabilityScore(
        'cast',
        (.45 * closure + .35 * (1 - o.normalCoherence) + .20 * (1 - flatness))
            .clamp(0, 1),
        [closed, normal, flat],
      ),
      ProbabilityScore(
        'organic',
        (.65 * (1 - o.normalCoherence) + .35 * (1 - closure)).clamp(0, 1),
        [normal, closed],
      ),
    ];
    return scores..sort((a, b) => b.probability.compareTo(a.probability));
  }
}
