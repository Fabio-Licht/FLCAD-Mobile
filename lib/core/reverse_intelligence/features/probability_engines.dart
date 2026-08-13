import '../models/intelligence_models.dart';

class FeatureProbabilityEngine {
  const FeatureProbabilityEngine();
  List<ProbabilityScore> estimate(MeshObservation o) {
    final open = (o.boundaryEdgeCount / (o.triangleCount * 3))
            .clamp(0, 1)
            .toDouble(),
        planar = o.normalCoherence;
    Evidence e(String id, double v) => Evidence(
      id: id,
      description: 'Measured mesh feature signal',
      value: v,
      source: 'observation',
    );
    return [
      ProbabilityScore('hole', open, [e('boundary_ratio', open)]),
      ProbabilityScore('pocket', (.6 * open + .4 * planar).clamp(0, 1), [
        e('boundary_planarity', planar),
      ]),
      ProbabilityScore('flange', planar * .7, [e('planarity', planar)]),
      ProbabilityScore('rib', planar * .5, [e('planarity', planar)]),
    ]..sort((a, b) => b.probability.compareTo(a.probability));
  }
}

class SurfaceProbabilityEngine {
  const SurfaceProbabilityEngine();
  List<ProbabilityScore> estimate(MeshObservation o) {
    final planar = o.normalCoherence, curved = 1 - planar;
    Evidence e(String id, double v) => Evidence(
      id: id,
      description: 'Normal distribution signal',
      value: v,
      source: 'observation.normals',
    );
    return [
      ProbabilityScore('plane', planar, [e('normal_coherence', planar)]),
      ProbabilityScore('cylinder', curved * .65, [
        e('normal_variation', curved),
      ]),
      ProbabilityScore('sphere', curved * .45, [e('normal_variation', curved)]),
      ProbabilityScore('nurbs', curved * .35, [e('normal_variation', curved)]),
    ]..sort((a, b) => b.probability.compareTo(a.probability));
  }
}
