import '../models/workflow_models.dart';

enum WorkflowIssueType {
  missingProject,
  invalidOrder,
  incompleteRequiredStep,
  invalidScore,
  closedWorkflow,
}

class WorkflowIssue {
  const WorkflowIssue(this.type, this.message);
  final WorkflowIssueType type;
  final String message;
}

class WorkflowValidationResult {
  const WorkflowValidationResult(this.issues);
  final List<WorkflowIssue> issues;
  bool get valid => issues.isEmpty;
}

class WorkflowValidator {
  const WorkflowValidator();
  WorkflowValidationResult validate(ReverseWorkflow workflow) {
    final issues = <WorkflowIssue>[];
    if (workflow.projectId.isEmpty) {
      issues.add(
        const WorkflowIssue(
          WorkflowIssueType.missingProject,
          'Project ID is required',
        ),
      );
    }
    if (workflow.currentIndex < 0 ||
        workflow.currentIndex >= workflow.steps.length) {
      issues.add(
        const WorkflowIssue(
          WorkflowIssueType.invalidOrder,
          'Invalid current workflow step',
        ),
      );
    }
    if (![
      workflow.engineeringScore,
      workflow.projectHealth,
    ].every((e) => e.isFinite && e >= 0 && e <= 100)) {
      issues.add(
        const WorkflowIssue(
          WorkflowIssueType.invalidScore,
          'Scores must be between 0 and 100',
        ),
      );
    }
    if (workflow.state == ReverseWorkflowState.closed) {
      issues.add(
        const WorkflowIssue(
          WorkflowIssueType.closedWorkflow,
          'Workflow is closed',
        ),
      );
    }
    return WorkflowValidationResult(issues);
  }
}
