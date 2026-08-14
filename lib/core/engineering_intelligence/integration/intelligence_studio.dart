import '../../engineering_studio/models/studio_models.dart';
import '../engine/engineering_intelligence_engine.dart';

class EngineeringIntelligenceStudioAdapter {
  const EngineeringIntelligenceStudioAdapter();
  static const workspace = 'Engineering Intelligence Workspace';
  static const panels = [
    'Recommendation Panel',
    'Project Health',
    'Engineering Dashboard',
    'Decision Timeline',
    'Recommendation History',
    'Engineering Score',
    'Project Diagnostics',
  ];
  List<EngineeringTreeNode> buildTree(
    EngineeringIntelligenceEngine engine,
    String projectId,
  ) => [
    for (final panel in panels)
      EngineeringTreeNode(
        id: 'intelligence:${panel.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: panel,
        type: StudioEntityType.analytics,
      ),
    if (engine.currentScore != null)
      EngineeringTreeNode(
        id: 'intelligence:project-health',
        projectId: projectId,
        name: 'Project Engineering Health',
        type: StudioEntityType.analytics,
        parentId: 'intelligence:engineering-dashboard',
        context: {
          'engineeringIntelligence': true,
          'engineeringScore': engine.currentScore!.overall,
          'projectHealth': engine.currentScore!.projectHealth,
          'lastRecommendation': engine.recommendations.values.lastOrNull?.title,
          'confidence': engine.recommendations.values.lastOrNull?.confidence,
          'reason': engine.recommendations.values.lastOrNull?.technicalReason,
          'expectedImprovement':
              engine.recommendations.values.lastOrNull?.expectedImprovement,
          'impact': engine.recommendations.values.lastOrNull?.affectedFeatures,
        },
      ),
  ];
}
