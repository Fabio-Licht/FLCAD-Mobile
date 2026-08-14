import '../../engineering_studio/models/studio_models.dart';
import '../engine/feature_engine.dart';

class FeatureStudioAdapter {
  const FeatureStudioAdapter();
  static const panels = [
    'Feature Tree',
    'Timeline',
    'Dependencies',
    'Parameters',
    'History',
    'Rebuild Queue',
    'Advisor',
    'Quality',
  ];
  List<EngineeringTreeNode> buildTree(
    FeatureModelingEngine e,
    String projectId,
  ) {
    final nodes = <EngineeringTreeNode>[
      for (final name in panels)
        EngineeringTreeNode(
          id: 'feature-platform:${name.toLowerCase().replaceAll(' ', '-')}',
          projectId: projectId,
          name: name,
          type: StudioEntityType.feature,
        ),
    ];
    for (final f in e.features.values) {
      final position = e.timeline.entries
          .firstWhere((x) => x.featureId == f.id)
          .position;
      nodes.add(
        EngineeringTreeNode(
          id: f.id,
          projectId: projectId,
          name: f.definition.name,
          type: StudioEntityType.feature,
          parentId: 'feature-platform:feature-tree',
          context: {
            'featurePlatform': true,
            'featureType': f.definition.type.name,
            'parameters': f.parameters,
            'references': f.inputs.map((i) => i.reference.id).toList(),
            'dependencies': f.dependencies,
            'timelinePosition': position,
            'executionState': f.state.name,
            'suppression': f.suppressed,
            'persistentId': f.id,
            'diagnostics': f.diagnostics,
          },
        ),
      );
    }
    return nodes;
  }
}
