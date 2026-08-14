import '../models/workflow_models.dart';

class ChecklistItem {
  const ChecklistItem(this.label, this.step, this.completed);
  final String label;
  final ReverseWorkflowStepType step;
  final bool completed;
  Map<String, dynamic> toJson() => {
    'label': label,
    'step': step.name,
    'completed': completed,
  };
}

class ReverseChecklist {
  const ReverseChecklist();
  List<ChecklistItem> build(ReverseWorkflow workflow) {
    bool done(ReverseWorkflowStepType type) =>
        workflow.steps.firstWhere((e) => e.type == type).state ==
        WorkflowStepState.completed;
    return [
      ChecklistItem(
        'STL imported',
        ReverseWorkflowStepType.importMesh,
        done(ReverseWorkflowStepType.importMesh),
      ),
      ChecklistItem(
        'Recognition completed',
        ReverseWorkflowStepType.recognition,
        done(ReverseWorkflowStepType.recognition),
      ),
      ChecklistItem(
        'Valid alignment',
        ReverseWorkflowStepType.alignment,
        done(ReverseWorkflowStepType.alignment),
      ),
      ChecklistItem(
        'Primary datum created',
        ReverseWorkflowStepType.referenceGeometry,
        done(ReverseWorkflowStepType.referenceGeometry),
      ),
      ChecklistItem(
        'Sketch created',
        ReverseWorkflowStepType.sketch,
        done(ReverseWorkflowStepType.sketch),
      ),
      ChecklistItem(
        'First feature created',
        ReverseWorkflowStepType.featureCreation,
        done(ReverseWorkflowStepType.featureCreation),
      ),
      ChecklistItem(
        'Validation active',
        ReverseWorkflowStepType.validation,
        done(ReverseWorkflowStepType.validation),
      ),
      ChecklistItem(
        'Engineering approved',
        ReverseWorkflowStepType.engineeringReview,
        done(ReverseWorkflowStepType.engineeringReview),
      ),
    ];
  }
}
