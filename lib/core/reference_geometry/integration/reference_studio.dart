import '../../engineering_studio/models/studio_models.dart';
import '../engine/reference_engine.dart';

class ReferenceStudioAdapter {
  const ReferenceStudioAdapter();
  static const workspace = 'Reverse Engineering Workspace';
  static const panels = [
    'Reference Manager',
    'Coordinate Systems',
    'Construction Geometry',
    'Reference Analytics',
  ];
  List<EngineeringTreeNode> buildTree(
    ReferenceEngine engine,
    String projectId,
  ) => [
    for (final panel in panels)
      EngineeringTreeNode(
        id: 'reference:${panel.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: panel,
        type: StudioEntityType.reference,
      ),
    for (final r in engine.references.values)
      EngineeringTreeNode(
        id: r.id,
        projectId: projectId,
        name: r.name,
        type: StudioEntityType.reference,
        parentId: 'reference:reference-manager',
        context: {
          'referenceGeometry': true,
          'referenceType': r.type.name,
          'constructionMethod': r.method.name,
          'dependencies': r.dependencies,
          'persistentId': r.id,
          'history': engine.history.entries
              .where((e) => e.target == r.id)
              .map((e) => e.toJson())
              .toList(),
          'quality': engine.quality(r.id).overall,
          'visibility': r.visible,
          'state': r.status.name,
        },
      ),
  ];
}
