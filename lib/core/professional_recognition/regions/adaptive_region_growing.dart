import '../../geometric_recognition/models/recognition_models.dart';

class RegionRefinementProposal {
  const RegionRefinementProposal(
    this.regionId,
    this.action,
    this.confidence,
    this.reasons,
  );
  final String regionId, action;
  final double confidence;
  final List<String> reasons;
}

class AdaptiveRegionGrowing {
  const AdaptiveRegionGrowing();
  List<RegionRefinementProposal> evaluate(List<RecognitionContext> regions) =>
      regions.map((context) {
        final o = context.observation,
            density = o.points.isEmpty
                ? 0.0
                : o.points.length /
                      (o.adjacency.isEmpty
                          ? o.points.length
                          : o.adjacency.length),
            curvature = o.curvatures.isEmpty
                ? 0.0
                : o.curvatures.map((e) => e.abs()).reduce((a, b) => a + b) /
                      o.curvatures.length,
            normalVariation = o.normals.length < 2
                ? 0.0
                : 1 -
                      o.normals
                              .map(
                                (n) => n.normalized
                                    .dot(o.normals.first.normalized)
                                    .abs(),
                              )
                              .reduce((a, b) => a + b) /
                          o.normals.length;
        final action = normalVariation > .35 || curvature > .5
            ? 'split'
            : density < .5
            ? 'refine'
            : 'keep';
        return RegionRefinementProposal(
          o.regionId,
          action,
          (normalVariation + curvature + (1 - density.clamp(0, 1))) / 3,
          [
            'curvature=$curvature',
            'normalVariation=$normalVariation',
            'density=$density',
          ],
        );
      }).toList();
}
