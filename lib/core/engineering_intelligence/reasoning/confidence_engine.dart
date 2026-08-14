import '../models/intelligence_models.dart';

class ConfidenceEngine {
  const ConfidenceEngine();
  double calculate(
    ProjectKnowledgeSnapshot snapshot, {
    double evidenceWeight = 1,
  }) {
    final evidence =
        snapshot.features +
        snapshot.references +
        snapshot.alignments +
        snapshot.validations +
        snapshot.sketches;
    return ((evidence / (evidence + 10)) * evidenceWeight)
        .clamp(0, 1)
        .toDouble();
  }
}
