import '../../engineering_intelligence/models/intelligence_models.dart';
import '../../reverse_workflow/models/workflow_models.dart';
import '../models/adaptive_studio_models.dart';

class QuickActionAdvisor {
  const QuickActionAdvisor();
  List<QuickAction> suggest(
    ReverseWorkflow workflow,
    Iterable<EngineeringRecommendation> recommendations,
  ) {
    final next = workflow.currentStep.type,
        matching = recommendations
            .where((e) => e.decision == RecommendationDecision.pending)
            .take(5);
    return [
      for (final recommendation in matching)
        QuickAction(
          id: 'quick:${recommendation.id}',
          label: recommendation.title,
          command: 'SHOW ${next.name.toUpperCase()}',
          recommendationId: recommendation.id,
          explanation: recommendation.explanation,
        ),
    ];
  }
}
