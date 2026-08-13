import '../../reverse_intelligence/models/intelligence_models.dart';
import '../models/cognition_models.dart';

class CognitionPartAnalyzer {
  const CognitionPartAnalyzer();
  List<PartClassification> analyze(
    ReasoningSnapshot arei,
    List<RecognizedFeature> features,
  ) {
    final evidence = <String, CognitionEvidence>{};
    CognitionEvidence ev(String label, double p) => evidence.putIfAbsent(
      label,
      () => CognitionEvidence(
        'arei.part.$label',
        'AREI part or manufacturing probability',
        p,
        'AREI',
      ),
    );
    final values = <PartClassification>[];
    for (final p in arei.classifications) {
      values.add(
        PartClassification(_map(p.label), p.probability, [
          ev(p.label, p.probability),
        ]),
      );
    }
    for (final p in arei.manufacturing) {
      values.add(
        PartClassification(_map(p.label), p.probability, [
          ev(p.label, p.probability),
        ]),
      );
    }
    final hybrid =
        values
            .take(3)
            .map((v) => v.probability)
            .fold<double>(0, (a, b) => a + b) /
        3;
    values.add(
      PartClassification('hybrid', hybrid * .65, [
        CognitionEvidence(
          'feature.diversity',
          'Diversity of recognized feature families',
          (features.map((f) => f.kind).toSet().length / 8)
              .clamp(0, 1)
              .toDouble(),
          'Engineering Cognition',
        ),
      ]),
    );
    final best = <String, PartClassification>{};
    for (final value in values) {
      if (value.probability > (best[value.kind]?.probability ?? -1)) {
        best[value.kind] = value;
      }
    }
    return best.values.toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
  }

  String _map(String label) => switch (label) {
    'prismatic' => 'prismatic',
    'turned' => 'revolution',
    'cast' || 'casting' => 'cast',
    'injectionMolding' => 'injected',
    'cncMachining' => 'machined',
    'organic' => 'organic',
    'sheetMetal' => 'sheetMetal',
    'welding' => 'welded',
    _ => label,
  };
}
