import '../../engineering_studio/models/studio_models.dart';
import '../engine/sketch_engine.dart';
import '../entities/sketch_entities.dart';

class SketchStudioAdapter {
  const SketchStudioAdapter();
  List<EngineeringTreeNode> buildTree(
    SketchEngine engine,
    String projectId,
  ) => [
    EngineeringTreeNode(
      id: 'sketch-tree',
      projectId: projectId,
      name: 'Sketches',
      type: StudioEntityType.sketch,
    ),
    ...engine.sketches.values.expand(
      (sketch) => [
        EngineeringTreeNode(
          id: sketch.id,
          projectId: projectId,
          name: sketch.name,
          type: StudioEntityType.sketch,
          context: {'persistentId': sketch.id, 'plane': sketch.plane.type.name},
          parentId: 'sketch-tree',
        ),
        ..._folder(
          projectId,
          sketch.id,
          'entities',
          'Entities',
          sketch.entityIds
              .map((id) => engine.entities[id])
              .whereType<SketchEntity>()
              .where((e) => !e.construction && !e.reference),
        ),
        ..._folder(
          projectId,
          sketch.id,
          'construction',
          'Construction',
          sketch.entityIds
              .map((id) => engine.entities[id])
              .whereType<SketchEntity>()
              .where((e) => e.construction),
        ),
        ..._folder(
          projectId,
          sketch.id,
          'references',
          'References',
          sketch.entityIds
              .map((id) => engine.entities[id])
              .whereType<SketchEntity>()
              .where((e) => e.reference),
        ),
      ],
    ),
  ];
  List<EngineeringTreeNode> _folder(
    String projectId,
    String sketchId,
    String key,
    String name,
    Iterable<SketchEntity> entities,
  ) {
    final folderId = '$key:$sketchId';
    return [
      EngineeringTreeNode(
        id: folderId,
        projectId: projectId,
        name: name,
        type: StudioEntityType.sketch,
        parentId: sketchId,
      ),
      ...entities.map(
        (e) => EngineeringTreeNode(
          id: e.id,
          projectId: projectId,
          name: e.type.name,
          type: StudioEntityType.sketch,
          parentId: folderId,
          visible: e.visible,
          locked: e.locked,
          context: {
            'persistentId': e.id,
            'entityType': e.type.name,
            'coordinates': e.parameters,
            'construction': e.construction,
            'reference': e.reference,
            'diagnostics': e.diagnostics,
          },
        ),
      ),
    ];
  }
}
