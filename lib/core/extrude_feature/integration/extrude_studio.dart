import '../../engineering_studio/models/studio_models.dart';
import '../engine/extrude_engine.dart';

class ExtrudeStudioAdapter {
  const ExtrudeStudioAdapter();
  static const panels = [
    'Extrude Tool',
    'Preview Panel',
    'Parameter Panel',
    'Advisor Panel',
    'Warnings',
    'Execution Status',
    'Feature Timeline',
    'Feature Tree',
  ];
  List<EngineeringTreeNode> buildTree(ExtrudeEngine e, String projectId) => [
    for (final name in panels)
      EngineeringTreeNode(
        id: 'extrude:${name.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: name,
        type: StudioEntityType.feature,
      ),
    for (final x in e.extrudes.values)
      EngineeringTreeNode(
        id: x.id,
        projectId: projectId,
        name: 'Extrude ${x.parameters.type.name}',
        type: StudioEntityType.feature,
        parentId: 'extrude:feature-tree',
        context: {
          'extrudeFeature': true,
          'extrudeType': x.parameters.type.name,
          'distance': x.parameters.distance,
          'direction': x.parameters.direction.toJson(),
          'profile': x.input.profileIds,
          'target': x.parameters.bodyTarget ?? x.parameters.surfaceTarget,
          'merge': x.parameters.merge,
          'draft': x.parameters.draftAngle,
          'persistentId': x.id,
          'history': x.history,
          'dependencies': x.dependencies,
          'kernelStatus': x.status.name,
          'quality': e.quality(x.id).overall,
        },
      ),
  ];
}
