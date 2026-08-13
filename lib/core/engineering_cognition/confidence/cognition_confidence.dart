import '../models/cognition_models.dart';

class CognitionConfidence {
  const CognitionConfidence();
  double evidenceWeighted(Iterable<CognitionEvidence> values) {
    final e = values.toList();
    if (e.isEmpty) return 0;
    final weight = e.fold<double>(0, (s, v) => s + v.reliability);
    return weight == 0
        ? 0
        : (e.fold<double>(
                    0,
                    (s, v) => s + v.value.clamp(0, 1) * v.reliability,
                  ) /
                  weight)
              .clamp(0, 1)
              .toDouble();
  }

  double combine(
    double arei,
    double knowledge,
    double geometry, {
    double coverage = 1,
  }) =>
      (arei * .35 + knowledge * .35 + geometry * .30).clamp(0, 1).toDouble() *
      coverage.clamp(0, 1);
}
