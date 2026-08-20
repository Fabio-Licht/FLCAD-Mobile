import 'dart:io';

import 'package:flcad_mobile/core/sketch_constraints/integration/constraint_factory.dart';
import 'package:flcad_mobile/core/sketch_editor/integration/editor_factory.dart';
import 'package:flcad_mobile/core/sketch_editor/models/editor_models.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_g126_');
  });

  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('Trim and Extend edit original geometry and support Undo/Redo', () {
    final sketch = const SketchEngineFactory().create(project)
      ..createSketch('Sketch001');
    final constraints = const ConstraintFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    final editor = const SketchEditorFactory().create(
      projectDirectory: project,
      sketch: sketch,
      constraints: constraints,
    );
    final line = sketch.builders.line.build(
      const SketchVector(0, 0),
      const SketchVector(10, 0),
    );

    editor.preview(SketchToolType.trim, const []);
    editor.edit(
      SketchToolType.trim,
      [line.id],
      parameters: {'point': const SketchVector(3, 0).toJson()},
    );
    expect(line.parameters['start'], [3.0, 0.0, 0.0]);

    editor.preview(SketchToolType.extend, const []);
    editor.edit(
      SketchToolType.extend,
      [line.id],
      parameters: {'point': const SketchVector(15, 0).toJson()},
    );
    expect(line.parameters['end'], [15.0, 0.0, 0.0]);
    expect(editor.undo(), isTrue);
    expect(editor.redo(), isTrue);
  });

  test('Fillet and Chamfer remain editable features with stable IDs', () {
    final sketch = const SketchEngineFactory().create(project)
      ..createSketch('Sketch001');
    final constraints = const ConstraintFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    final editor = const SketchEditorFactory().create(
      projectDirectory: project,
      sketch: sketch,
      constraints: constraints,
    );
    final a = sketch.builders.line.build(
      const SketchVector(0, 0),
      const SketchVector(10, 0),
    );
    final b = sketch.builders.line.build(
      const SketchVector(0, 0),
      const SketchVector(0, 10),
    );
    editor.preview(SketchToolType.fillet, const []);
    editor.edit(SketchToolType.fillet, [a.id, b.id], value: 1);
    final fillet = sketch.engine.entities.values.whereType<SketchArc>().single;
    fillet.metadata.addAll({
      'featureType': 'fillet',
      'featureValue': 1.0,
      'sourceEntityIds': [a.id, b.id],
      'autoTrim': true,
    });
    final stableId = fillet.id;

    editor.editCornerFeature(stableId, 2);

    expect(sketch.entity(stableId), same(fillet));
    expect(fillet.parameters['radius'], 2);
    expect(fillet.metadata['featureValue'], 2);
  });

  test('Geomagic-style Trim removes a clicked endpoint overhang', () {
    final sketch = const SketchEngineFactory().create(project)
      ..createSketch('Sketch001');
    final constraints = const ConstraintFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    final editor = const SketchEditorFactory().create(
      projectDirectory: project,
      sketch: sketch,
      constraints: constraints,
    );
    final horizontal = sketch.builders.line.build(
      const SketchVector(0, 0),
      const SketchVector(10, 0),
    );
    sketch.builders.line.build(
      const SketchVector(4, -3),
      const SketchVector(4, 3),
    );

    editor.trimEndpointToNearestIntersection(
      horizontal.id,
      const SketchVector(0.1, 0),
    );

    expect(horizontal.parameters['start'], [4.0, 0.0, 0.0]);
    expect(horizontal.parameters['end'], [10.0, 0.0, 0.0]);
  });

  test('two-side Trim preserves the portions explicitly clicked', () {
    final sketch = const SketchEngineFactory().create(project)
      ..createSketch('Sketch001');
    final constraints = const ConstraintFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    final editor = const SketchEditorFactory().create(
      projectDirectory: project,
      sketch: sketch,
      constraints: constraints,
    );
    final horizontal = sketch.builders.line.build(
      const SketchVector(0, 0),
      const SketchVector(10, 0),
    );
    final vertical = sketch.builders.line.build(
      const SketchVector(4, -5),
      const SketchVector(4, 5),
    );

    editor.trimIntersection(
      horizontal.id,
      const SketchVector(8, 0),
      vertical.id,
      const SketchVector(4, -3),
    );

    expect(horizontal.parameters['start'], [4.0, 0.0, 0.0]);
    expect(horizontal.parameters['end'], [10.0, 0.0, 0.0]);
    expect(vertical.parameters['start'], [4.0, -5.0, 0.0]);
    expect(vertical.parameters['end'], [4.0, 0.0, 0.0]);
  });
}
