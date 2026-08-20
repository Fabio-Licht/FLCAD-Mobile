import '../../engineering_studio/models/studio_models.dart';
import '../engine/constraint_engine.dart';
import '../models/constraint_models.dart';

class ConstraintStudioAdapter {
  const ConstraintStudioAdapter();
  List<EngineeringTreeNode> buildTree(
    ConstraintEngine engine,
    String projectId,
  ) {
    const folders = [
      'Constraints',
      'Dimensions',
      'Solver Status',
      'Conflicts',
      'Diagnostics',
    ];
    final nodes = <EngineeringTreeNode>[
      for (final name in folders)
        EngineeringTreeNode(
          id: 'constraint:${name.toLowerCase().replaceAll(' ', '-')}',
          projectId: projectId,
          name: name,
          type: StudioEntityType.sketch,
        ),
    ];
    final parent = nodes.first.id;
    final dimensionsParent = nodes[1].id;
    nodes.addAll(
      engine.constraints.values.map(
        (c) => EngineeringTreeNode(
          id: c.id,
          projectId: projectId,
          name: c.type.name,
          type: StudioEntityType.sketch,
          parentId: parent,
          context: {
            'constraintType': c.type.name,
            'status': c.status.name,
            'driving': c.driving,
            'driven': c.driven,
            'priority': c.priority,
            'solved': c.status == ConstraintStatus.satisfied,
            'references': c.references,
            'diagnostics': c.diagnostics,
            'timestamp': c.timestamp.toIso8601String(),
            'persistentId': c.id,
          },
        ),
      ),
    );
    nodes.addAll(
      engine.dimensions.values.map(
        (dimension) => EngineeringTreeNode(
          id: dimension.id,
          projectId: projectId,
          name: '${dimension.type.name} ${dimension.value}',
          type: StudioEntityType.sketch,
          parentId: dimensionsParent,
          context: {
            'dimensionType': dimension.type.name,
            'value': dimension.value,
            'references': dimension.references,
            'anchorReference': dimension.anchorReference,
            'labelPosition': [dimension.labelX, dimension.labelY],
            'visible': dimension.visible,
            'persistentId': dimension.id,
          },
        ),
      ),
    );
    return nodes;
  }
}
