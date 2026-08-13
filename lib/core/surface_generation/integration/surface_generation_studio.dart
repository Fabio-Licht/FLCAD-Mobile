import '../../engineering_studio/models/studio_models.dart';
import '../../engineering_studio/tree/engineering_tree_manager.dart';
import '../models/surface_generation_models.dart';

class SurfaceGenerationStudioIntegration {
  const SurfaceGenerationStudioIntegration();
  EngineeringTreeNode root(String projectId) => EngineeringTreeNode(
    id: '$projectId-generated-surfaces',
    projectId: projectId,
    name: 'Generated Surfaces',
    type: StudioEntityType.generatedSurfaces,
  );
  EngineeringTreeNode node(
    GeneratedSurface surface,
    String parentId,
    int index,
  ) => EngineeringTreeNode(
    id: surface.surfaceId,
    projectId: surface.projectId,
    name:
        '${surface.kind.name[0].toUpperCase()}${surface.kind.name.substring(1)}${index.toString().padLeft(3, '0')}',
    type: StudioEntityType.generatedSurface,
    parentId: parentId,
    status: surface.valid ? 'valid' : 'invalid',
    confidence: surface.confidence,
    context: {
      'surfaceType': surface.kind.name,
      'parameters': surface.parameters,
      'regions': surface.regionIds,
      'predictedContinuity': surface.continuity.name,
      'evidence': surface.evidenceIds,
      'shapeHandle': surface.handle.toJson(),
      'persistentId': surface.handle.persistentId,
      'revision': surface.revision,
      'valid': surface.valid,
      'diagnostics': surface.diagnostics.map((e) => e.message).toList(),
    },
  );
  void populate(
    EngineeringTreeManager tree,
    String projectId,
    List<GeneratedSurface> surfaces,
  ) {
    final parent = root(projectId);
    tree.add(parent);
    for (var i = 0; i < surfaces.length; i++) {
      tree.add(node(surfaces[i], parent.id, i + 1));
    }
  }
}
