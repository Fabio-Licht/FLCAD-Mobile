import '../../engineering_studio/models/studio_models.dart';
import '../workspace/adaptive_workspace_engine.dart';

class AdaptiveStudioAdapter {
  const AdaptiveStudioAdapter();
  static const workspace = 'Adaptive Reverse Engineering Studio';
  List<EngineeringTreeNode> buildTree(
    AdaptiveWorkspaceEngine engine,
    String projectId,
  ) => [
    for (final state in engine.workspaces.values)
      EngineeringTreeNode(
        id: state.id,
        projectId: projectId,
        name: workspace,
        type: StudioEntityType.workflow,
        context: {
          'adaptiveStudio': true,
          'currentWorkspace': state.context.name,
          'currentMode': state.focusMode?.name ?? 'adaptive',
          'currentFeature': state.currentFeature,
          'workflowStep': state.workflowStep,
          'quickAction': state.activeQuickAction,
          'engineeringRecommendation': state.engineeringRecommendation,
        },
      ),
  ];
}
