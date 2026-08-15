import '../models/ai_engineering_models.dart';

class ConfidenceWeights {
  ConfidenceWeights(Map<String, double> values)
    : values = Map.unmodifiable(values) {
    const required = {
      'geometric',
      'topology',
      'manufacturing',
      'continuity',
      'symmetry',
      'history',
      'userPreference',
    };
    if (!this.values.keys.toSet().containsAll(required) ||
        this.values.values.any((value) => value < 0) ||
        this.values.values.fold<double>(0, (a, b) => a + b) <= 0) {
      throw ArgumentError.value(values, 'values', 'invalid confidence weights');
    }
  }
  final Map<String, double> values;
  static final equal = ConfidenceWeights({
    for (final key in const [
      'geometric',
      'topology',
      'manufacturing',
      'continuity',
      'symmetry',
      'history',
      'userPreference',
    ])
      key: 1,
  });
}

class ConfidenceEngine {
  const ConfidenceEngine(this.weights);
  final ConfidenceWeights weights;
  IntentConfidence calculate({
    required double geometric,
    required double topology,
    required double manufacturing,
    required double continuity,
    required double symmetry,
    required double history,
    required double userPreference,
  }) {
    final values = {
      'geometric': geometric,
      'topology': topology,
      'manufacturing': manufacturing,
      'continuity': continuity,
      'symmetry': symmetry,
      'history': history,
      'userPreference': userPreference,
    };
    if (values.values.any((value) => value < 0 || value > 1)) {
      throw RangeError('Confidence inputs must be in [0, 1]');
    }
    final denominator = weights.values.values.fold<double>(0, (a, b) => a + b);
    final overall =
        values.entries.fold<double>(
          0,
          (sum, entry) => sum + entry.value * weights.values[entry.key]!,
        ) /
        denominator;
    return IntentConfidence(
      weights: weights.values,
      score: IntentScore(
        geometricScore: geometric,
        topologyScore: topology,
        manufacturingScore: manufacturing,
        continuityScore: continuity,
        symmetryScore: symmetry,
        historyScore: history,
        userPreferenceScore: userPreference,
        overallConfidence: overall,
      ),
    );
  }
}
