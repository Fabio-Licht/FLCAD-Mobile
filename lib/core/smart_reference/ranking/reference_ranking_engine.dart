import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../models/smart_reference_models.dart';

class ReferenceRankingWeights {
  ReferenceRankingWeights(Map<String, double> values)
    : values = Map.unmodifiable(values) {
    const keys = {
      'geometric',
      'topology',
      'manufacturing',
      'functional',
      'symmetry',
      'feature',
      'context',
      'history',
    };
    if (!this.values.keys.toSet().containsAll(keys) ||
        this.values.values.any((e) => e < 0) ||
        this.values.values.fold<double>(0, (a, b) => a + b) <= 0) {
      throw ArgumentError.value(
        values,
        'values',
        'invalid reference ranking weights',
      );
    }
  }
  final Map<String, double> values;
  static final equal = ReferenceRankingWeights({
    for (final key in const [
      'geometric',
      'topology',
      'manufacturing',
      'functional',
      'symmetry',
      'feature',
      'context',
      'history',
    ])
      key: 1,
  });
}

class ReferenceRankingEngine {
  const ReferenceRankingEngine(this.weights);
  final ReferenceRankingWeights weights;
  ReferenceScores calculate(EngineeringFeatureHypothesis feature) {
    final values = {
      'geometric': feature.scores.geometricScore,
      'topology': feature.scores.topologyScore,
      'manufacturing': feature.scores.manufacturingScore,
      'functional': feature.scores.functionalScore,
      'symmetry': feature.scores.symmetryScore,
      'feature': feature.scores.overallConfidence,
      'context': feature.scores.contextScore,
      'history': feature.scores.historyScore,
    };
    final denominator = weights.values.values.fold<double>(0, (a, b) => a + b);
    final overall =
        values.entries.fold<double>(
          0,
          (sum, e) => sum + e.value * weights.values[e.key]!,
        ) /
        denominator;
    return ReferenceScores(
      geometricScore: values['geometric']!,
      topologyScore: values['topology']!,
      manufacturingScore: values['manufacturing']!,
      functionalScore: values['functional']!,
      symmetryScore: values['symmetry']!,
      featureScore: values['feature']!,
      contextScore: values['context']!,
      historyScore: values['history']!,
      overallConfidence: overall,
    );
  }

  List<ReferenceCandidate> rank(Iterable<ReferenceCandidate> values) =>
      List.unmodifiable(
        values.toList()..sort((a, b) {
          final score = b.scores.overallConfidence.compareTo(
            a.scores.overallConfidence,
          );
          return score != 0 ? score : a.id.compareTo(b.id);
        }),
      );
}
