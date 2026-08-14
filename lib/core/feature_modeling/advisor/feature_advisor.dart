import '../engine/feature_engine.dart';

class FeatureRecommendation {
  const FeatureRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.impact,
    required this.alternatives,
    required this.pros,
    required this.cons,
  });
  final String title, explanation, impact;
  final int confidence;
  final List<String> alternatives, pros, cons;
}

class FeatureAdvisor {
  const FeatureAdvisor();
  List<FeatureRecommendation> analyze(FeatureModelingEngine e) {
    final out = <FeatureRecommendation>[];
    if (e.timeline.rebuildQueue.isNotEmpty) {
      out.add(
        FeatureRecommendation(
          title: 'Review rebuild queue',
          confidence: 90,
          explanation: '${e.timeline.rebuildQueue.length} features are dirty',
          impact: 'Reduces unexpected downstream changes',
          alternatives: const ['Partial rebuild', 'Complete rebuild'],
          pros: const ['Controlled execution'],
          cons: const ['Requires review'],
        ),
      );
    }
    if (e.validation.issues.isNotEmpty) {
      out.add(
        FeatureRecommendation(
          title: 'Repair feature dependencies',
          confidence: 95,
          explanation:
              '${e.validation.issues.length} validation issues detected',
          impact: 'Improves model stability',
          alternatives: const [
            'Restore references',
            'Suppress dependent feature',
          ],
          pros: const ['Stable history'],
          cons: const ['Manual decision required'],
        ),
      );
    }
    return out;
  }
}
