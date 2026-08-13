import '../models/intelligence_models.dart';

class IntelligenceSerialization {
  const IntelligenceSerialization();
  Map<String, dynamic> snapshot(ReasoningSnapshot s) => {
    'schema': 'flcad.arei.snapshot',
    'version': 1,
    'projectId': s.projectId,
    'meshId': s.meshId,
    'createdAt': s.createdAt.toIso8601String(),
    'observation': s.observation.toJson(),
    'classifications': s.classifications.map((v) => v.toJson()).toList(),
    'manufacturing': s.manufacturing.map((v) => v.toJson()).toList(),
    'hypotheses': s.hypotheses
        .map(
          (h) => {
            'id': h.id,
            'statement': h.statement,
            'kind': h.kind,
            'confidence': h.confidence,
            'status': h.status.name,
          },
        )
        .toList(),
    'plan': {
      'id': s.plan.id,
      'rationale': s.plan.rationale,
      'steps': s.plan.steps
          .map(
            (v) => {
              'order': v.order,
              'operation': v.operation,
              'reason': v.reason,
              'requiredConfidence': v.requiredConfidence,
            },
          )
          .toList(),
    },
    'decision': {
      'strategyId': s.decision.selected.id,
      'confidence': s.decision.confidence,
      'explanation': s.decision.explanation,
    },
    'validation': {
      'valid': s.validation.valid,
      'score': s.validation.score,
      'findings': s.validation.findings,
    },
  };
}
