import '../models/decision_models.dart';
import '../policies/decision_policy.dart';

class MultiCriteriaDecisionSystem {
  const MultiCriteriaDecisionSystem();
  DecisionScore score(DecisionCriteria c, DecisionPolicyProfile profile) {
    final values = <String, double>{
      'recognition': c.recognitionConfidence,
      'mesh': c.meshQuality,
      'capture': c.captureCompleteness,
      'cost': 1 - c.computationalCost,
      'impact': c.reconstructionImpact,
      'reuse': c.referenceReuse,
      'complexity': 1 - c.partComplexity,
      'intent': c.engineeringIntent,
      'history': c.successHistory,
    };
    var weighted = 0.0, total = 0.0;
    for (final entry in values.entries) {
      final weight = profile.weights[entry.key] ?? 1;
      weighted += entry.value.clamp(0, 1) * weight;
      total += weight;
    }
    return DecisionScore(
      total == 0 ? 0 : weighted / total,
      Map.unmodifiable(values),
      profile.policy,
    );
  }
}
