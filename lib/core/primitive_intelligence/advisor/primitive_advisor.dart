import '../models/primitive_intelligence_models.dart';

class PrimitiveAdvisor {
  const PrimitiveAdvisor();
  List<PrimitiveRecommendation> advise(PrimitiveIntelligenceSession session) =>
      List.unmodifiable(
        session.hypotheses.map(
          (value) => PrimitiveRecommendation(
            id: '${value.id}:recommendation',
            hypothesisId: value.id,
            text: value.suggestion,
            justification: value.justification,
            evidence: value.evidence,
          ),
        ),
      );
}
