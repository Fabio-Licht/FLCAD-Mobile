import '../features/engineering_feature.dart';

class FeatureAdvice {
  const FeatureAdvice(this.action, this.reason, this.confidence);
  final String action, reason;
  final double confidence;
}

class FeatureAdvisor {
  const FeatureAdvisor();
  List<FeatureAdvice> advise(EngineeringFeature f) => switch (f.kind) {
    FeatureKind.hole => const [
      FeatureAdvice('thread', 'Consider thread or countersink', .8),
      FeatureAdvice('pattern', 'Check repeated hole pattern', .7),
    ],
    FeatureKind.fillet => const [
      FeatureAdvice(
        'manufacturing-radius',
        'Validate minimum tool radius',
        .85,
      ),
    ],
    _ => const [],
  };
}
