import '../models/hybrid_surface_models.dart';

class HybridStrategyEngine {
  const HybridStrategyEngine();
  List<HybridStrategy> compare(
    List<SurfaceNetworkNode> nodes,
    List<HybridRegion> regions,
  ) {
    final count = nodes.length,
        confidence = nodes.isEmpty
            ? 0.0
            : nodes
                      .map((e) => e.candidate.confidence)
                      .fold<double>(0, (a, b) => a + b) /
                  count,
        quality = nodes.isEmpty
            ? 0.0
            : nodes
                      .map((e) => e.candidate.quality)
                      .fold<double>(0, (a, b) => a + b) /
                  count;
    HybridStrategy make(
      String id,
      String name,
      double compression,
      double freeformCost,
      String explanation,
    ) {
      final cost = (count / 10 * .5 + freeformCost).clamp(0, 1).toDouble(),
          robustness = (confidence * (1 - freeformCost * .25))
              .clamp(0, 1)
              .toDouble(),
          maintainability = (compression * .6 + robustness * .4)
              .clamp(0, 1)
              .toDouble(),
          editability = (compression * .7 + (1 - cost) * .3)
              .clamp(0, 1)
              .toDouble(),
          inspection = (robustness * .7 + quality * .3).clamp(0, 1).toDouble(),
          manufacturing = (robustness * .6 + maintainability * .4)
              .clamp(0, 1)
              .toDouble(),
          score =
              (quality * .2 +
                      robustness * .2 +
                      maintainability * .15 +
                      editability * .1 +
                      inspection * .1 +
                      manufacturing * .15 +
                      (1 - cost) * .1)
                  .clamp(0, 1)
                  .toDouble();
      return HybridStrategy(
        id: id,
        name: name,
        surfaceIds: nodes.map((e) => e.candidate.id).toList(),
        score: score,
        quality: quality,
        cost: cost,
        maintainability: maintainability,
        robustness: robustness,
        editability: editability,
        inspectability: inspection,
        manufacturability: manufacturing,
        explanation: explanation,
      );
    }

    final values = [
      make(
        'hybrid-analytic-transition',
        'Analytical + transitions',
        .85,
        .2,
        'Preserves analytical regions and plans explicit transitions',
      ),
      make(
        'single-nurbs',
        'Single NURBS',
        .65,
        .75,
        'Reduces surface count but increases freeform cost and inspection risk',
      ),
      make(
        'patch-network',
        'Patch network',
        .45,
        .55,
        'Local patches isolate irregular regions and preserve editability',
      ),
    ];
    values.sort((a, b) => b.score.compareTo(a.score));
    return values;
  }
}
