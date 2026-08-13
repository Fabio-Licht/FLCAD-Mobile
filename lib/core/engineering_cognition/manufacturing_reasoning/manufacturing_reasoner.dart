import '../models/cognition_models.dart';

class ManufacturingCognitionReasoner {
  const ManufacturingCognitionReasoner();
  List<ManufacturingAssessment> reason(
    List<RecognizedFeature> features,
    List<PartClassification> part,
  ) {
    final dominant = part.isEmpty ? 'unknown' : part.first.kind;
    return features.map((f) {
      final mapping = _map(f.kind, dominant);
      return ManufacturingAssessment(
        f.id,
        mapping.$1,
        mapping.$2,
        f.confidence * .85,
        'Project drawing, verified material/process specification, or applicable standard',
        '${f.kind} geometry and $dominant part evidence suggest ${mapping.$1}; tool and tolerance require production context.',
      );
    }).toList();
  }

  (String, String) _map(String feature, String part) => switch (feature) {
    'hole' || 'recess' => ('machining', 'drill or boring tool family'),
    'thread' => ('machining', 'tap or thread-milling tool family'),
    'pocket' || 'slot' => ('machining', 'end-mill tool family'),
    'chamfer' => ('machining', 'chamfer tool family'),
    'fillet' => ('machiningOrCasting', 'radius tool or casting fillet'),
    'rib' || 'reinforcement' =>
      part == 'injected'
          ? ('injectionMolding', 'mold core/cavity')
          : ('castingOrAdditive', 'process-dependent'),
    _ => ('processUndetermined', 'requires manufacturing evidence'),
  };
}
