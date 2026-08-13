import '../models/reconstruction_models.dart';

class ReconstructionAdvisor {
  const ReconstructionAdvisor();
  ReconstructionUiState state(ReconstructionWorkflow workflow) {
    final next = workflow.nextStep;
    return ReconstructionUiState(
      workflow.id,
      workflow.progress,
      next?.name,
      next?.dependencies ?? const [],
      next?.decision.confidence ?? 0,
      next?.decision.alternatives ?? const [],
      next?.decision.explanation ??
          (workflow.progress == 1
              ? 'Workflow complete'
              : workflow.paused
              ? 'Workflow paused'
              : 'No executable stage; inspect blockers.'),
      workflow.paused,
    );
  }
}
