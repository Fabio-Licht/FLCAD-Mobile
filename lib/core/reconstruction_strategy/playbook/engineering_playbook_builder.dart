import '../models/reconstruction_strategy_models.dart';

class EngineeringPlaybookBuilder {
  const EngineeringPlaybookBuilder();
  EngineeringPlaybook build(
    String sessionId,
    List<ReconstructionStrategy> strategies,
    String partProfile,
  ) {
    if (strategies.isEmpty) {
      throw StateError('At least one strategy is required');
    }
    final recommended = [...strategies]
      ..sort((a, b) {
        final score = b.confidence.compareTo(a.confidence);
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    return EngineeringPlaybook(
      id: '$sessionId:playbook',
      partProfile: partProfile,
      recommendedStrategyId: recommended.first.id,
      steps: recommended.first.steps,
      justification:
          'Recommended strategy has the highest auditable confidence; ties use stable strategy ID.',
      auditVersion: 0,
    );
  }
}
