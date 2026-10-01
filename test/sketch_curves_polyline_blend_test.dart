import 'dart:io';

import 'package:flcad_mobile/core/sketch_constraints/integration/constraint_factory.dart';
import 'package:flcad_mobile/core/sketch_editor/integration/editor_factory.dart';
import 'package:flcad_mobile/core/sketch_editor/models/editor_models.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/geometry/sketch_spline_geometry.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_sketch_curves_');
  });

  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('interpolated spline crosses every clicked knot and survives JSON', () {
    const knots = [
      SketchVector(0, 0),
      SketchVector(4, 3),
      SketchVector(9, -2),
      SketchVector(12, 1),
    ];
    final spline = SketchSpline(knots);
    final samples = (spline.parameters['sampledPoints'] as List)
        .map(SketchVector.fromJson)
        .toList();
    expect(samples.first.toJson(), knots.first.toJson());
    expect(samples[24].toJson(), knots[1].toJson());
    expect(samples[48].toJson(), knots[2].toJson());
    expect(samples.last.toJson(), knots.last.toJson());
    final reopened = SketchEntity.fromJson(spline.toJson()) as SketchSpline;
    expect(reopened.parameters, spline.parameters);
    expect(
      () => SketchSpline(const [SketchVector(0, 0), SketchVector(0, 0)]),
      throwsArgumentError,
    );
  });

  test('polyline is one undo step with separate connected Sketch lines', () {
    final sketch = const SketchEngineFactory().create(project)
      ..createSketch('Sketch001');
    final editor = const SketchEditorFactory().create(
      projectDirectory: project,
      sketch: sketch,
      constraints: const ConstraintFactory().create(
        projectDirectory: project,
        sketch: sketch,
      ),
    );
    final operation = editor.preview(SketchToolType.polyline, const [
      SketchVector(0, 0),
      SketchVector(10, 0),
      SketchVector(10, 10),
      SketchVector(0, 0),
    ]);
    final created = editor.confirm(operation.id);
    expect(created, hasLength(3));
    expect(created, everyElement(isA<SketchLine>()));
    expect(editor.undo(), isTrue);
    expect(sketch.engine.entities, isEmpty);
    expect(editor.redo(), isTrue);
    expect(sketch.engine.entities, hasLength(3));
  });

  test('Bezier Blend joins independent line endpoints with G1 tangency', () {
    const a = SketchVector(0, 0), b = SketchVector(10, 0);
    const c = SketchVector(14, 4), d = SketchVector(14, 14);
    final controls = SketchTangentBlendGeometry.betweenLines(
      a,
      b,
      c,
      d,
      tangentLength: 3,
    );
    expect(controls.first.toJson(), b.toJson());
    expect(controls.last.toJson(), c.toJson());
    final outgoing = controls[1] - controls[0];
    final incoming = controls[3] - controls[2];
    expect(outgoing.y, closeTo(0, 1e-12));
    expect(outgoing.x, greaterThan(0));
    expect(incoming.x, closeTo(0, 1e-12));
    expect(incoming.y, greaterThan(0));
    final spline = SketchSpline([b, c], bezierControls: controls);
    expect(spline.parameters['interpolation'], 'cubicBezierG1');
    expect(
      SketchEntity.fromJson(spline.toJson()).parameters,
      spline.parameters,
    );
  });

  test('Blend rejects degenerate, coincident and invalid tangent length', () {
    expect(
      () => SketchTangentBlendGeometry.betweenLines(
        const SketchVector(0, 0),
        const SketchVector(0, 0),
        const SketchVector(2, 0),
        const SketchVector(3, 0),
        tangentLength: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => SketchTangentBlendGeometry.betweenLines(
        const SketchVector(0, 0),
        const SketchVector(1, 0),
        const SketchVector(1, 0),
        const SketchVector(2, 0),
        tangentLength: 2,
      ),
      throwsArgumentError,
    );
  });
}
