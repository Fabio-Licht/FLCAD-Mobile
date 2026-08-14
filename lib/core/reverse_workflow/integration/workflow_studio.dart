import '../../engineering_studio/models/studio_models.dart';
import '../engine/reverse_workflow_engine.dart';

class ReverseWorkflowStudioAdapter {
  const ReverseWorkflowStudioAdapter();
  static const workspace = 'Professional Reverse Engineering Workspace';
  static const panels = [
    'Reverse Dashboard',
    'Workflow',
    'Checklist',
    'Recommendations',
    'Current Operation',
    'Progress',
    'Engineering Status',
  ];
  List<EngineeringTreeNode> buildTree(
    ReverseWorkflowEngine engine,
    String projectId,
  ) => [
    for (final panel in panels)
      EngineeringTreeNode(
        id: 'reverse-workflow:${panel.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: panel,
        type: StudioEntityType.workflow,
      ),
    for (final workflow in engine.workflows.values)
      EngineeringTreeNode(
        id: workflow.id,
        projectId: projectId,
        name: workflow.name,
        type: StudioEntityType.workflow,
        parentId: 'reverse-workflow:workflow',
        context: {
          'reverseWorkflow': true,
          'workflowState': workflow.state.name,
          'progress': workflow.progress,
          'currentStep': workflow.currentStep.type.name,
          'engineeringScore': workflow.engineeringScore,
          'projectHealth': workflow.projectHealth,
          'recommendations': workflow.recommendationIds,
        },
      ),
  ];
}
