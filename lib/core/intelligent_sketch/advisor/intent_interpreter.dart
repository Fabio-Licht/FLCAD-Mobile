import '../models/sketch.dart';

class EngineeringIntent {
  const EngineeringIntent(this.kind, this.confidence, this.downstreamUses);
  final String kind;
  final double confidence;
  final List<String> downstreamUses;
}

class IntentInterpreter {
  const IntentInterpreter();
  EngineeringIntent interpret(IntelligentSketch sketch) {
    if (sketch.analytics.closed) {
      return const EngineeringIntent('closed-profile', .85, [
        'reconstruction',
        'cad',
        'cam',
      ]);
    }
    if (sketch.analytics.degree > 1) {
      return const EngineeringIntent('guide-curve', .75, [
        'surface',
        'reconstruction',
      ]);
    }
    return const EngineeringIntent('construction-geometry', .6, [
      'inspection',
      'cad',
    ]);
  }
}
