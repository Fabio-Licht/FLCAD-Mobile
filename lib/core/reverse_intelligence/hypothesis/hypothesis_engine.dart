import '../models/intelligence_models.dart';

class HypothesisEngine {
  const HypothesisEngine();
  List<EngineeringHypothesis> generate(
    MeshObservation observation,
    List<ProbabilityScore> classifications,
  ) {
    final result = <EngineeringHypothesis>[];
    for (final c in classifications.where((v) => v.probability >= .35)) {
      final statement = switch (c.label) {
        'prismatic' =>
          'Dominant regions are likely bounded by engineering planes',
        'turned' =>
          'The part may be organized around a principal revolution axis',
        'cast' => 'Surface variation may originate from a casting process',
        'organic' => 'Freeform surface reconstruction may be required',
        _ => 'Unclassified geometric organization',
      };
      result.add(
        EngineeringHypothesis(
          id: '${observation.meshId}:${c.label}',
          statement: statement,
          kind: c.label,
          confidence: c.probability,
          evidence: c.evidence,
          alternatives: classifications
              .where((x) => x.label != c.label)
              .take(2)
              .map((x) => x.label)
              .toList(),
        ),
      );
    }
    return result;
  }
}
