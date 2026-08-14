import '../models/workflow_models.dart';
import '../workflow/reverse_checklist.dart';

class WorkflowRecommendation {
  const WorkflowRecommendation({
    required this.nextStep,
    required this.pending,
    required this.optional,
    required this.critical,
    required this.risks,
    required this.checklist,
    required this.explanation,
  });
  final ReverseWorkflowStepType? nextStep;
  final List<ReverseWorkflowStepType> pending, optional, critical;
  final List<String> risks;
  final List<ChecklistItem> checklist;
  final String explanation;
}

class WorkflowAdvisor {
  const WorkflowAdvisor();
  WorkflowRecommendation analyze(ReverseWorkflow workflow) {
    final pending = workflow.steps
            .where(
              (s) =>
                  s.state != WorkflowStepState.completed &&
                  s.state != WorkflowStepState.skipped,
            )
            .toList(),
        optional = pending.where((s) => s.optional).map((s) => s.type).toList(),
        critical = pending
            .where(
              (s) => {
                ReverseWorkflowStepType.importMesh,
                ReverseWorkflowStepType.alignment,
                ReverseWorkflowStepType.validation,
                ReverseWorkflowStepType.engineeringReview,
              }.contains(s.type),
            )
            .map((s) => s.type)
            .toList();
    return WorkflowRecommendation(
      nextStep: pending.firstOrNull?.type,
      pending: pending.map((s) => s.type).toList(),
      optional: optional,
      critical: critical,
      risks: [
        if (workflow.engineeringScore < 70) 'Engineering score below target',
        if (workflow.projectHealth < 70) 'Project health requires review',
        if (workflow.diagnostics.isNotEmpty) ...workflow.diagnostics,
      ],
      checklist: const ReverseChecklist().build(workflow),
      explanation: pending.isEmpty
          ? 'Workflow complete'
          : 'Proceed only after user confirms ${pending.first.type.name}',
    );
  }
}
