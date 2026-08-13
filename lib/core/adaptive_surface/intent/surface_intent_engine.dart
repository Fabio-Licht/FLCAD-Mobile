import '../models/adaptive_surface.dart';

class SurfaceIntent {
  const SurfaceIntent(this.kind, this.weights, this.confidence);
  final String kind;
  final Map<String, double> weights;
  final double confidence;
}

class SurfaceIntentEngine {
  const SurfaceIntentEngine();
  SurfaceIntent infer({
    String? declaredIntent,
    ManufacturingProcess process = ManufacturingProcess.unknown,
  }) {
    final intent =
        declaredIntent ??
        switch (process) {
          ManufacturingProcess.machining => 'machining',
          ManufacturingProcess.casting => 'functional',
          ManufacturingProcess.forming => 'aesthetic',
          ManufacturingProcess.additive => 'functional',
          ManufacturingProcess.molding => 'aesthetic',
          ManufacturingProcess.unknown => 'general',
        };
    final weights = switch (intent) {
      'support' => const {
        'accuracy': .45,
        'continuity': .15,
        'manufacturing': .4,
      },
      'aesthetic' => const {
        'accuracy': .15,
        'continuity': .55,
        'manufacturing': .3,
      },
      'functional' => const {
        'accuracy': .55,
        'continuity': .3,
        'manufacturing': .15,
      },
      'machining' => const {
        'accuracy': .4,
        'continuity': .1,
        'manufacturing': .5,
      },
      _ => const {'accuracy': .34, 'continuity': .33, 'manufacturing': .33},
    };
    return SurfaceIntent(intent, weights, declaredIntent == null ? .65 : 1.0);
  }
}
