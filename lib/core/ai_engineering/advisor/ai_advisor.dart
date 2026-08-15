import '../models/ai_engineering_models.dart';

class AIAdvisor {
  const AIAdvisor();
  List<AIRecommendation> advise(EngineeringIntent intent) => List.unmodifiable(
    intent.candidates.map(
      (candidate) => AIRecommendation(
        id: '${candidate.id}:recommendation',
        candidateId: candidate.id,
        priority: RecommendationPriority.medium,
        suggestion: IntentSuggestion(
          candidateId: candidate.id,
          text: 'Review the ${candidate.type.name} hypothesis.',
          technicalJustification: candidate.rationale,
        ),
        evidence: candidate.evidence,
      ),
    ),
  );
}
