import '../models/intelligence_models.dart';

class ConfidenceEngine {
  const ConfidenceEngine();
  double combine(Iterable<Evidence> evidence) {
    final values = evidence.toList();
    if (values.isEmpty) return 0;
    final weight = values.fold<double>(0, (s, e) => s + e.reliability);
    if (weight == 0) return 0;
    return (values.fold<double>(
              0,
              (s, e) => s + e.value.clamp(0, 1) * e.reliability,
            ) /
            weight)
        .clamp(0, 1)
        .toDouble();
  }

  double calibrate(double raw, {double evidenceCoverage = 1}) =>
      (raw * evidenceCoverage).clamp(0, 1).toDouble();
}
