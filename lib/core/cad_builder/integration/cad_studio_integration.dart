import '../../engineering_studio/models/studio_models.dart';
import '../../engineering_studio/tree/engineering_tree_manager.dart';
import '../models/cad_models.dart';

class CadStudioIntegration {
  const CadStudioIntegration();
  EngineeringTreeNode node(CadEntity entity, {String? parentId}) =>
      EngineeringTreeNode(
        id: entity.handle.persistentId,
        projectId: entity.projectId,
        name: '${entity.handle.type.name} ${entity.handle.persistentId}',
        type: StudioEntityType.values.byName(entity.handle.type.name),
        parentId: parentId,
        status: entity.valid ? 'valid' : 'invalid',
        context: {
          'origin': entity.origin,
          'dependencies': entity.dependencies,
          'valid': entity.valid,
          'persistentId': entity.handle.persistentId,
          'diagnostics': entity.diagnostics.map((e) => e.message).toList(),
          'analytics': entity.statistics,
        },
      );
  void add(EngineeringTreeManager tree, CadEntity entity, {String? parentId}) =>
      tree.add(node(entity, parentId: parentId));
}
