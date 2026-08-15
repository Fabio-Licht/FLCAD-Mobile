import '../models/engineering_feature_models.dart';

class FeatureConfidenceWeights {
  FeatureConfidenceWeights(Map<String, double> values)
    : values = Map.unmodifiable(values) {
    const keys = {
      'geometric',
      'topology',
      'functional',
      'manufacturing',
      'symmetry',
      'context',
      'history',
    };
    if (!this.values.keys.toSet().containsAll(keys) ||
        this.values.values.any((e) => e < 0) ||
        this.values.values.fold<double>(0, (a, b) => a + b) <= 0) {
      throw ArgumentError.value(
        values,
        'values',
        'invalid feature confidence weights',
      );
    }
  }
  final Map<String, double> values;
  static final equal = FeatureConfidenceWeights({
    for (final key in const [
      'geometric',
      'topology',
      'functional',
      'manufacturing',
      'symmetry',
      'context',
      'history',
    ])
      key: 1,
  });
}

class FeatureConfidenceEngine {
  const FeatureConfidenceEngine(this.weights);
  final FeatureConfidenceWeights weights;
  FeatureScores calculate(Map<String, double> values) {
    final normalized = {
      for (final key in weights.values.keys) key: values[key] ?? 0,
    };
    if (normalized.values.any((e) => e < 0 || e > 1)) {
      throw RangeError('Feature scores must be in [0, 1]');
    }
    final denominator = weights.values.values.fold<double>(0, (a, b) => a + b);
    final overall =
        normalized.entries.fold<double>(
          0,
          (sum, e) => sum + e.value * weights.values[e.key]!,
        ) /
        denominator;
    return FeatureScores(
      geometricScore: normalized['geometric']!,
      topologyScore: normalized['topology']!,
      functionalScore: normalized['functional']!,
      manufacturingScore: normalized['manufacturing']!,
      symmetryScore: normalized['symmetry']!,
      contextScore: normalized['context']!,
      historyScore: normalized['history']!,
      overallConfidence: overall,
    );
  }

  FeatureConfidenceNode tree(
    String id,
    FeatureScores scores,
    List<FeatureEvidence> evidence,
  ) => FeatureConfidenceNode(
    id: '$id:confidence',
    label: 'Feature Confidence',
    confidence: scores.overallConfidence,
    evidenceIds: evidence.map((e) => e.id),
    children: [
      FeatureConfidenceNode(
        id: '$id:geometric',
        label: 'Geometric',
        confidence: scores.geometricScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
      FeatureConfidenceNode(
        id: '$id:topology',
        label: 'Topology',
        confidence: scores.topologyScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
      FeatureConfidenceNode(
        id: '$id:functional',
        label: 'Functional',
        confidence: scores.functionalScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
      FeatureConfidenceNode(
        id: '$id:manufacturing',
        label: 'Manufacturing',
        confidence: scores.manufacturingScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
      FeatureConfidenceNode(
        id: '$id:symmetry',
        label: 'Symmetry',
        confidence: scores.symmetryScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
      FeatureConfidenceNode(
        id: '$id:context',
        label: 'Context',
        confidence: scores.contextScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
      FeatureConfidenceNode(
        id: '$id:history',
        label: 'History',
        confidence: scores.historyScore,
        children: const [],
        evidenceIds: evidence.map((e) => e.id),
      ),
    ],
  );
}
