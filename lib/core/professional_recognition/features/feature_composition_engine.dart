import '../../geometric_recognition/models/recognition_models.dart';
import '../models/professional_recognition_models.dart';

class FeatureCompositionEngine {
  const FeatureCompositionEngine();
  List<ProfessionalFeature> compose(
    List<ProfessionalPrimitive> primitives,
    List<TopologicalRelation> relations,
    List<RecognizedPattern> patterns,
  ) {
    final features = <ProfessionalFeature>[];
    for (final primitive in primitives) {
      final candidate = primitive.recognition.winner;
      if (candidate.type == PrimitiveType.cylinder) {
        final confidence = primitive.recognition.dna.confidence * .85;
        features.add(
          ProfessionalFeature(
            id: 'feature:hole:${candidate.id}',
            type: ManufacturingFeatureType.throughHole,
            regionIds: [candidate.regionId],
            primitiveIds: [candidate.id],
            confidence: confidence,
            explanation:
                'Cilindro reconhecido; classificação through-hole é provável e requer validação de limites.',
            dna:
                'feature:throughHole:${primitive.recognition.dna.geometricSignature}',
            evidence: [
              'primitive:${candidate.id}',
              'boundary:not-yet-classified',
            ],
          ),
        );
      }
    }
    for (final relation in relations.where(
      (r) => r.type == TopologicalRelationType.coaxial,
    )) {
      final members = features
          .where((f) => f.primitiveIds.any(relation.primitiveIds.contains))
          .toList();
      if (members.length >= 2) {
        features.add(
          ProfessionalFeature(
            id: 'feature:counterbore:${relation.id}',
            type: ManufacturingFeatureType.counterbore,
            regionIds: members.expand((e) => e.regionIds).toSet().toList(),
            primitiveIds: relation.primitiveIds,
            confidence: relation.confidence * .8,
            explanation:
                'Dois cilindros coaxiais sugerem counterbore; profundidade deve ser validada.',
            dna: 'feature:counterbore:${relation.id}',
            evidence: ['relation:${relation.id}'],
          ),
        );
      }
    }
    for (final pattern in patterns) {
      features.add(
        ProfessionalFeature(
          id: 'feature:pattern:${pattern.id}',
          type: ManufacturingFeatureType.pattern,
          regionIds: const [],
          primitiveIds: pattern.memberIds,
          confidence: pattern.confidence,
          explanation: pattern.explanation,
          dna: 'feature:pattern:${pattern.id}',
          evidence: ['pattern:${pattern.id}'],
        ),
      );
    }
    return features;
  }
}
