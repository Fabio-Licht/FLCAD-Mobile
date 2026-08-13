import 'dart:math' as math;

import '../models/recognition_models.dart';
import '../statistics/statistical_engine.dart';

class RecognitionCandidateSeed {
  const RecognitionCandidateSeed(
    this.regionId,
    this.suggestedTypes,
    this.descriptors,
  );
  final String regionId;
  final List<PrimitiveType> suggestedTypes;
  final Map<String, double> descriptors;
}

class CandidateGenerator {
  const CandidateGenerator();
  RecognitionCandidateSeed generate(RecognitionContext context) {
    final observation = context.observation;
    if (observation.points.length < 3) {
      return RecognitionCandidateSeed(observation.regionId, const [
        PrimitiveType.unknown,
      ], const {});
    }
    final pca = const RecognitionStatisticalEngine().pca(observation),
        variances = pca.variances.map((e) => e.abs()).toList(),
        total = math.max(variances.fold<double>(0, (a, b) => a + b), 1e-15),
        planarity = 1 - variances.last / total,
        curvatureMean = observation.curvatures.isEmpty
            ? 0.0
            : observation.curvatures
                      .map((e) => e.abs())
                      .fold<double>(0, (a, b) => a + b) /
                  observation.curvatures.length,
        normalCoherence = observation.normals.isEmpty
            ? 0.0
            : _normalCoherence(observation);
    final types = <PrimitiveType>[PrimitiveType.plane];
    if (observation.points.length >= 4) types.add(PrimitiveType.sphere);
    if (observation.points.length >= 6) types.add(PrimitiveType.cylinder);
    if (observation.points.length >= 7) types.add(PrimitiveType.cone);
    if (observation.points.length >= 10) types.add(PrimitiveType.torus);
    return RecognitionCandidateSeed(observation.regionId, types, {
      'planarity': planarity,
      'curvatureMean': curvatureMean,
      'normalCoherence': normalCoherence,
      'areaProxy': total,
      'adjacencyDensity': observation.adjacency.isEmpty
          ? 0
          : observation.adjacency.values.fold<int>(
                  0,
                  (sum, values) => sum + values.length,
                ) /
                observation.adjacency.length,
    });
  }

  double _normalCoherence(RecognitionObservation observation) {
    final mean =
        observation.normals.reduce((a, b) => a + b) /
        observation.normals.length.toDouble();
    return observation.normals
            .map((n) => n.normalized.dot(mean.normalized).abs())
            .fold<double>(0, (a, b) => a + b) /
        observation.normals.length.toDouble();
  }
}
