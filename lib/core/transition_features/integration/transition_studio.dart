import '../../engineering_studio/models/studio_models.dart';
import '../engine/transition_engine.dart';

class TransitionStudioAdapter {
  const TransitionStudioAdapter();
  static const panels = [
    'Sweep Tool',
    'Loft Tool',
    'Transition Preview',
    'Transition Timeline',
    'Advisor Panel',
    'Diagnostics',
    'Feature Tree',
    'Execution Status',
  ];
  List<EngineeringTreeNode> buildTree(
    TransitionEngine engine,
    String projectId,
  ) => [
    for (final panel in panels)
      EngineeringTreeNode(
        id: 'transition:${panel.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: panel,
        type: StudioEntityType.feature,
      ),
    for (final f in engine.features.values)
      EngineeringTreeNode(
        id: f.id,
        projectId: projectId,
        name: '${f.family.name} transition',
        type: StudioEntityType.feature,
        parentId: 'transition:feature-tree',
        context: {
          'transitionFeature': true,
          'transitionType': f.family.name,
          'profiles': f.input.profileIds,
          'sections': f.input.sectionIds,
          'paths': f.input.pathIds,
          'guides': f.input.guideIds,
          'references': f.input.referenceIds,
          'shapeHandle': f.output?.persistentId,
          'kernelStatus': f.status.name,
          'dependencies': f.dependencies,
          'history': engine.history.entries
              .where((e) => e.target == f.id)
              .map((e) => e.toJson())
              .toList(),
          'quality': engine.quality(f.id).overall,
        },
      ),
  ];
}
