import '../../professional_workflow/models/workflow_models.dart' as workflow;
import '../models/decision_models.dart';

class ProfessionalWorkflowDecisionAdapter {
  const ProfessionalWorkflowDecisionAdapter();
  workflow.WorkflowRecommendation toRecommendation(
    EngineeringDecision decision,
    workflow.ProfessionalWorkflowStage stage,
  ) => workflow.WorkflowRecommendation(
    id: decision.id,
    stage: stage,
    title: decision.title,
    actionLabel: 'Aceitar decisão',
    targetArtifactId: decision.regionId,
    decision: workflow.ExplainableDecision(
      why: decision.justification,
      evidence: decision.evidence
          .map(
            (e) => workflow.WorkflowEvidence(
              id: e.id,
              description: e.description,
              source: e.source,
              weight: e.value,
            ),
          )
          .toList(),
      alternatives: decision.alternatives.map((e) => e.name).toList(),
      confidence: decision.confidence,
      impact: decision.impact,
    ),
  );
}
