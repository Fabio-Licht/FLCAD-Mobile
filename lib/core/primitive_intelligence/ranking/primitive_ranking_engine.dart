import '../models/primitive_intelligence_models.dart';

class PrimitiveRankingWeights {
  PrimitiveRankingWeights(Map<String, double> values)
    : values = Map.unmodifiable(values) {
    const keys = {
      'confidence',
      'importance',
      'manufacturing',
      'alignment',
      'reconstruction',
    };
    if (!this.values.keys.toSet().containsAll(keys) ||
        this.values.values.any((e) => e < 0) ||
        this.values.values.fold<double>(0, (a, b) => a + b) <= 0) {
      throw ArgumentError.value(values, 'values', 'invalid ranking weights');
    }
  }
  final Map<String, double> values;
  static final equal = PrimitiveRankingWeights({
    for (final key in const [
      'confidence',
      'importance',
      'manufacturing',
      'alignment',
      'reconstruction',
    ])
      key: 1,
  });
}

class PrimitiveRankingEngine {
  const PrimitiveRankingEngine(this.weights);
  final PrimitiveRankingWeights weights;
  PrimitiveScores score(PrimitiveObservation value) {
    final components = {
      'confidence': value.recognitionConfidence,
      'importance': value.measures['importance'] ?? 0,
      'manufacturing': value.measures['manufacturingRelevance'] ?? 0,
      'alignment': value.measures['alignmentRelevance'] ?? 0,
      'reconstruction': value.measures['reconstructionRelevance'] ?? 0,
    };
    if (components.values.any((e) => e < 0 || e > 1)) {
      throw RangeError('Ranking components must be in [0, 1]');
    }
    final totalWeight = weights.values.values.fold<double>(0, (a, b) => a + b);
    final overall =
        components.entries.fold<double>(
          0,
          (sum, e) => sum + e.value * weights.values[e.key]!,
        ) /
        totalWeight;
    return PrimitiveScores(
      confidence: components['confidence']!,
      importance: components['importance']!,
      manufacturingRelevance: components['manufacturing']!,
      alignmentRelevance: components['alignment']!,
      reconstructionRelevance: components['reconstruction']!,
      overall: overall,
    );
  }

  List<PrimitiveHypothesis> rank(Iterable<PrimitiveHypothesis> values) =>
      List.unmodifiable(
        values.toList()..sort((a, b) {
          final score = b.scores.overall.compareTo(a.scores.overall);
          return score != 0 ? score : a.id.compareTo(b.id);
        }),
      );
}
