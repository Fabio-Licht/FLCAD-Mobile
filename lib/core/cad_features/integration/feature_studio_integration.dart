import '../../engineering_studio/models/studio_models.dart';
import '../../engineering_studio/tree/engineering_tree_manager.dart';
import '../models/feature_models.dart';

class FeatureStudioIntegration {
  const FeatureStudioIntegration();
  EngineeringTreeNode body(String projectId) => EngineeringTreeNode(
    id: '$projectId-cad-body',
    projectId: projectId,
    name: 'Body',
    type: StudioEntityType.body,
  );
  EngineeringTreeNode node(
    CadFeature feature, {
    required String bodyId,
  }) => EngineeringTreeNode(
    id: feature.id,
    projectId: feature.projectId,
    name: '${feature.kind.name}${feature.revision.toString().padLeft(3, '0')}',
    type: StudioEntityType.cadFeature,
    parentId: bodyId,
    status: feature.status.name,
    context: {
      'featureId': feature.id,
      'parameters': feature.parameters,
      'shapeHandle': feature.output?.toJson(),
      'persistentIds': feature.inputs.map((e) => e.persistentId).toList(),
      'valid': feature.status == CadFeatureStatus.valid,
      'history': feature.revision,
      'dependencies': feature.dependencies,
      'buildTimeMicros': feature.buildTime.inMicroseconds,
      'analytics': {
        'operation': feature.kind.name,
        'elapsedMicros': feature.buildTime.inMicroseconds,
      },
    },
  );
  void add(
    EngineeringTreeManager tree,
    CadFeature feature, {
    required String bodyId,
  }) => tree.add(node(feature, bodyId: bodyId));
}
