import '../../geometric_recognition/models/recognition_models.dart';
import '../models/primitive_intelligence_models.dart';

class PrimitiveEvidenceBuilder {
  const PrimitiveEvidenceBuilder();
  List<PrimitiveEvidence> build(PrimitiveObservation value) {
    final fields = switch (value.type) {
      PrimitiveType.plane => const [
        'area',
        'orientation',
        'position',
        'continuity',
        'neighborhood',
        'parallelism',
        'perpendicularity',
      ],
      PrimitiveType.cylinder => const [
        'radius',
        'length',
        'coaxiality',
        'concentricity',
        'adjacency',
        'continuity',
      ],
      PrimitiveType.cone => const [
        'angle',
        'direction',
        'probableDraft',
        'continuity',
      ],
      PrimitiveType.sphere => const ['radius', 'center', 'symmetry'],
      PrimitiveType.torus => const ['majorRadius', 'minorRadius', 'coaxiality'],
      _ => const ['recognitionConfidence'],
    };
    return List.unmodifiable(
      fields.map((field) {
        final vector = value.vectors[field];
        final Object measured =
            vector ?? value.measures[field] ?? _derived(field, value);
        return PrimitiveEvidence(
          field: field,
          value: measured,
          source: vector != null || value.measures.containsKey(field)
              ? 'recognition.snapshot.$field'
              : 'recognition.snapshot.relations',
          justification:
              'Observed $field for recognized ${value.type.name} ${value.id}.',
        );
      }),
    );
  }

  Object _derived(String field, PrimitiveObservation value) => switch (field) {
    'adjacency' || 'neighborhood' => value.adjacentIds.length,
    'orientation' || 'direction' =>
      value.vectors['axis'] ?? value.vectors['normal'] ?? const <double>[],
    'position' || 'center' => value.vectors['center'] ?? const <double>[],
    'recognitionConfidence' => value.recognitionConfidence,
    _ => 0.0,
  };
}
