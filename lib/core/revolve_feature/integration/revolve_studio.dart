import '../../engineering_studio/models/studio_models.dart';
import '../engine/revolve_engine.dart';

class RevolveStudioAdapter {
  const RevolveStudioAdapter();
  static const panels = [
    'Revolve Tool',
    'Axis Selector',
    'Preview Panel',
    'Parameter Panel',
    'Advisor',
    'Timeline',
    'Feature Tree',
    'Diagnostics',
  ];
  List<EngineeringTreeNode> buildTree(RevolveEngine e, String projectId) => [
    for (final name in panels)
      EngineeringTreeNode(
        id: 'revolve:${name.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: name,
        type: StudioEntityType.feature,
      ),
    for (final r in e.revolves.values)
      EngineeringTreeNode(
        id: r.id,
        projectId: projectId,
        name: 'Revolve ${r.parameters.type.name}',
        type: StudioEntityType.feature,
        parentId: 'revolve:feature-tree',
        context: {
          'revolveFeature': true,
          'revolveType': r.parameters.type.name,
          'axis': r.input.axis.toJson(),
          'angle': r.parameters.angle,
          'direction': r.parameters.reverse ? 'reverse' : 'forward',
          'merge': r.parameters.merge,
          'body': r.parameters.bodyTarget,
          'references': [
            r.parameters.faceReference,
            r.parameters.planeReference,
            r.parameters.vertexReference,
          ].whereType<String>().toList(),
          'persistentId': r.id,
          'history': r.history,
          'dependencies': r.dependencies,
          'quality': e.quality(r.id).overall,
          'kernelStatus': r.status.name,
        },
      ),
  ];
}
