import '../models/intelligence_models.dart';

class SymmetryAssessment {
  const SymmetryAssessment(this.kind, this.confidence, this.evidence);
  final String kind;
  final double confidence;
  final List<Evidence> evidence;
}

class SymmetryEngine {
  const SymmetryEngine();
  List<SymmetryAssessment> analyze(MeshObservation o) {
    final dimensions = [o.axisExtents.x, o.axisExtents.y, o.axisExtents.z],
        max = dimensions.reduce((a, b) => a > b ? a : b);
    if (max == 0) return const [];
    final pairs = <SymmetryAssessment>[];
    for (var i = 0; i < 3; i++) {
      for (var j = i + 1; j < 3; j++) {
        final score = (1 - (dimensions[i] - dimensions[j]).abs() / max)
                .clamp(0, 1)
                .toDouble(),
            e = Evidence(
              id: 'extent_similarity_$i$j',
              description: 'Similarity between principal extents',
              value: score,
              source: 'observation.axisExtents',
            );
        pairs.add(SymmetryAssessment('axisPair$i$j', score, [e]));
      }
    }
    return pairs..sort((a, b) => b.confidence.compareTo(a.confidence));
  }
}
