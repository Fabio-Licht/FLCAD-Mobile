import '../models/cognition_models.dart';

class EngineeringIntentEngine {
  const EngineeringIntentEngine();
  List<EngineeringIntent> infer(List<RecognizedFeature> features) {
    final grouped = <String, List<RecognizedFeature>>{};
    for (final feature in features) {
      final function = _function(feature.kind);
      (grouped[function] ??= []).add(feature);
    }
    return grouped.entries.map((entry) {
      final confidence = entry.value
          .map((v) => v.confidence)
          .reduce((a, b) => a > b ? a : b);
      return EngineeringIntent(
        entry.key,
        confidence,
        '${entry.value.map((v) => v.kind).join(', ')} commonly supports ${entry.key}; this is a probabilistic functional interpretation, not a design specification.',
        entry.value.map((v) => v.id).toList(),
        entry.value.expand((v) => v.evidence).toList(),
      );
    }).toList()..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  String _function(String kind) => switch (kind) {
    'hole' || 'thread' || 'flange' => 'fastening',
    'seat' || 'housing' || 'boss' => 'support',
    'guide' || 'slot' => 'guidance',
    'sealSeat' => 'sealing',
    'rib' || 'reinforcement' => 'reinforcement',
    'pocket' || 'oilGroove' => 'flowOrClearance',
    'chamfer' || 'fillet' => 'transition',
    _ => 'geometricDefinition',
  };
}
