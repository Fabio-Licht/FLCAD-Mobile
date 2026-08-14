import '../../engineering_studio/models/studio_models.dart';
import '../engine/live_validation_engine.dart';

class ValidationStudioAdapter {
  const ValidationStudioAdapter();
  static const workspace = 'Validation Workspace';
  static const panels = [
    'Live Dashboard',
    'Heat Map Panel',
    'Deviation Inspector',
    'Tolerance Manager',
    'Critical Regions',
    'Validation Timeline',
    'Validation Analytics',
  ];
  List<EngineeringTreeNode> buildTree(
    LiveValidationEngine engine,
    String projectId,
  ) => [
    for (final panel in panels)
      EngineeringTreeNode(
        id: 'validation:${panel.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: panel,
        type: StudioEntityType.analytics,
      ),
    for (final s in engine.sessions.values)
      EngineeringTreeNode(
        id: s.id,
        projectId: projectId,
        name: '${s.source.type.name} validation',
        type: StudioEntityType.analytics,
        parentId: 'validation:live-dashboard',
        context: {
          'liveValidation': true,
          'maximumError': s.metrics?.maximumDeviation,
          'averageError': s.metrics?.averageDeviation,
          'rms': s.metrics?.rms,
          'tolerance': s.parameters.tolerance,
          'quality': s.metrics?.overallQuality,
          'confidence': s.metrics?.confidence,
          'lastUpdate': s.updatedAt.toIso8601String(),
          'affectedRegions': s.affectedRegions,
          'responsibleFeature': s.responsibleFeature,
        },
      ),
  ];
}
