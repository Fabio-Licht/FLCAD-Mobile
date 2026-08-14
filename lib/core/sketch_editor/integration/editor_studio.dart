import '../../engineering_studio/models/studio_models.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../engine/sketch_editor_engine.dart';

class SketchEditorStudioAdapter {
  const SketchEditorStudioAdapter();
  List<EngineeringTreeNode> buildTree(
    SketchEngineApi sketch,
    ConstraintApi constraints,
    SketchEditorEngine editor,
    String projectId,
  ) {
    final nodes = <EngineeringTreeNode>[
      EngineeringTreeNode(
        id: 'editor:sketch',
        projectId: projectId,
        name: 'Sketch',
        type: StudioEntityType.sketch,
      ),
    ];
    void folder(String key, String name, int count) {
      if (count > 0) {
        nodes.add(
          EngineeringTreeNode(
            id: 'editor:$key',
            projectId: projectId,
            name: name,
            type: StudioEntityType.sketch,
            parentId: 'editor:sketch',
          ),
        );
      }
    }

    final entities = sketch.engine.entities.values;
    folder(
      'entities',
      'Entities',
      entities.where((e) => !e.construction && !e.reference).length,
    );
    folder(
      'construction',
      'Construction',
      entities.where((e) => e.construction).length,
    );
    folder('reference', 'Reference', entities.where((e) => e.reference).length);
    folder('constraints', 'Constraints', constraints.constraints.length);
    folder('dimensions', 'Dimensions', constraints.engine.dimensions.length);
    folder('selection', 'Selection', editor.selection.selected.length);
    for (final e in entities) {
      nodes.add(
        EngineeringTreeNode(
          id: e.id,
          projectId: projectId,
          name: e.type.name,
          type: StudioEntityType.sketch,
          parentId: e.construction
              ? 'editor:construction'
              : e.reference
              ? 'editor:reference'
              : 'editor:entities',
          visible: e.visible,
          locked: e.locked,
          context: {
            'editorEntity': true,
            'coordinates': e.parameters,
            'length': e.parameters['length'],
            'radius': e.parameters['radius'],
            'diameter': e.parameters['radius'] is num
                ? (e.parameters['radius'] as num) * 2
                : null,
            'angle': e.parameters['rotation'],
            'construction': e.construction,
            'reference': e.reference,
            'driving': false,
            'driven': false,
            'constraintCount': constraints.constraints
                .where((c) => c.references.contains(e.id))
                .length,
            'degreesOfFreedom': editor.readDof().remaining,
            'selectionState': e.selectionState.name,
            'persistentId': e.id,
            'history': e.history,
            'diagnostics': e.diagnostics,
          },
        ),
      );
    }
    return nodes;
  }

  static const panels = [
    'Sketch Toolbar',
    'Sketch Status',
    'Selection Panel',
    'Snap Panel',
    'DOF Panel',
    'Quality Panel',
    'Advisor Panel',
    'Preview Layer',
  ];
}
