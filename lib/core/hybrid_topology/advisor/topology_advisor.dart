import '../hybrid/hybrid_object.dart';

class TopologyAdvice {
  const TopologyAdvice(this.action, this.reason, this.confidence);
  final String action, reason;
  final double confidence;
}

class TopologyAdvisor {
  const TopologyAdvisor();
  List<TopologyAdvice> advise(HybridObject object) {
    final a = object.analytics;
    return [
      if (a.noise > .2)
        const TopologyAdvice('repair', 'Noise exceeds topology threshold', .85),
      if (a.quality < .7)
        const TopologyAdvice(
          'preserve-features',
          'Protect critical features before morphing',
          .8,
        ),
      if (a.density > .8)
        const TopologyAdvice(
          'local-workspace',
          'Use AEW for incremental processing',
          .75,
        ),
    ];
  }
}
