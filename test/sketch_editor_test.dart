import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/sketch_constraints/integration/constraint_factory.dart';
import 'package:flcad_mobile/core/sketch_constraints/api/constraint_api.dart';
import 'package:flcad_mobile/core/sketch_constraints/models/constraint_models.dart';
import 'package:flcad_mobile/core/sketch_editor/analytics/editor_analytics.dart';
import 'package:flcad_mobile/core/sketch_editor/api/sketch_editor_api.dart';
import 'package:flcad_mobile/core/sketch_editor/commands/fel_editor_commands.dart';
import 'package:flcad_mobile/core/sketch_editor/history/editor_history.dart';
import 'package:flcad_mobile/core/sketch_editor/integration/editor_factory.dart';
import 'package:flcad_mobile/core/sketch_editor/integration/editor_studio.dart';
import 'package:flcad_mobile/core/sketch_editor/models/editor_models.dart';
import 'package:flcad_mobile/core/sketch_editor/render/editor_render.dart';
import 'package:flcad_mobile/core/sketch_editor/repository/editor_repository.dart';
import 'package:flcad_mobile/core/sketch_editor/runtime/editor_runtime.dart';
import 'package:flcad_mobile/core/sketch_editor/selection/editor_selection.dart';
import 'package:flcad_mobile/core/sketch_editor/snapping/editor_snapping.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/api/sketch_engine_api.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;
  late SketchEngineApi sketch;
  late ConstraintApi constraints;
  late SketchEditorApi editor;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_editor_');
    sketch = const SketchEngineFactory().create(project)
      ..createSketch('Interactive');
    constraints = const ConstraintFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    editor = const SketchEditorFactory().create(
      projectDirectory: project,
      sketch: sketch,
      constraints: constraints,
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('creation tools require preview and commit parametric geometry', () {
    final line = editor.preview(SketchToolType.line, const [
      SketchVector(0, 0),
      SketchVector(2, 2),
    ]);
    expect(editor.engine.preview.active, hasLength(1));
    final created = editor.confirm(line.id);
    expect(created.single, isA<SketchLine>());
    expect(line.status, EditorOperationStatus.committed);
    final rectangle = editor.preview(SketchToolType.rectangle, const [
      SketchVector(0, 0),
      SketchVector(4, 3),
    ]);
    expect(editor.confirm(rectangle.id), hasLength(4));
    final circle = editor.preview(SketchToolType.circle, const [
      SketchVector(0, 0),
      SketchVector(2, 0),
    ]);
    expect(editor.confirm(circle.id).single, isA<SketchCircle>());
    final polygon = editor.preview(
      SketchToolType.polygon,
      const [SketchVector(0, 0), SketchVector(2, 0)],
      parameters: {'sides': 6},
    );
    expect(editor.confirm(polygon.id), hasLength(6));
  });

  test('editing preview rollback and undo redo sequence', () {
    final p = editor.preview(SketchToolType.point, const [SketchVector(0, 0)]);
    final point = editor.confirm(p.id).single;
    expect(
      () => editor.edit(SketchToolType.move, [
        point.id,
      ], delta: const SketchVector(1, 1)),
      throwsStateError,
    );
    editor.preview(SketchToolType.move, const []);
    editor.edit(SketchToolType.move, [
      point.id,
    ], delta: const SketchVector(1, 1));
    expect(point.parameters['translation'], [1.0, 1.0, 0.0]);
    expect(editor.undo(), isTrue);
    expect(editor.redo(), isTrue);
    final bad = editor.preview(SketchToolType.circle, const [
      SketchVector(0, 0),
      SketchVector(0, 0),
    ]);
    expect(() => editor.confirm(bad.id), throwsArgumentError);
    expect(
      editor.engine.history.entries.last.action,
      EditorHistoryAction.rollback,
    );
  });

  test('1000 selections groups persistence hover preview and filters', () {
    final point = sketch.builders.point.build(const SketchVector(0, 0));
    for (var i = 0; i < 1000; i++) {
      editor.engine.selection.select(point, multi: true, persist: true);
    }
    editor.engine.selection
      ..createGroup('primary', [point.id])
      ..hover(point)
      ..preselect(point)
      ..preview(point.id)
      ..highlight(point.id)
      ..restorePersistent();
    expect(editor.engine.selection.history, hasLength(1001));
    expect(editor.engine.selection.groups['primary'], contains(point.id));
    expect(
      editor.engine.selection.window([
        point,
      ], const EditorSelectionFilter(types: {SketchEntityType.point})),
      [point],
    );
  });

  test('1000 snaps produce endpoint preview diagnostics architecture', () {
    final point = sketch.builders.point.build(const SketchVector(1, 1));
    for (var i = 0; i < 1000; i++) {
      expect(
        editor.engine.snapping.snap(const SketchVector(1, 1), [point])?.type,
        EditorSnapType.endpoint,
      );
    }
    expect(editor.engine.analytics.snapCount, 1000);
    expect(editor.engine.snapping.preview, isNotNull);
    expect(EditorSnapType.values, hasLength(13));
  });

  test('1000 dynamic previews can be cancelled without mutation', () {
    final ids = <String>[];
    for (var i = 0; i < 1000; i++) {
      ids.add(
        editor.preview(SketchToolType.line, [
          SketchVector(i.toDouble(), 0),
          SketchVector(i.toDouble(), 1),
        ]).id,
      );
    }
    expect(editor.engine.preview.active, hasLength(1000));
    for (final id in ids) {
      editor.cancel(id);
    }
    expect(editor.engine.preview.active, isEmpty);
    expect(sketch.engine.entities, isEmpty);
  });

  test('DOF quality and advisor only read solver results', () async {
    final a = sketch.builders.point.build(const SketchVector(0, 0));
    final b = sketch.builders.point.build(const SketchVector(1, 1));
    constraints.builders.of(SketchConstraintType.fixed).build([a.id]);
    await constraints.solve();
    final dof = editor.dof,
        quality = editor.quality,
        recommendations = editor.recommendations;
    expect(dof.remaining, greaterThan(0));
    expect(quality.score, inInclusiveRange(0, 100));
    expect(SketchQualityGrade.values, contains(quality.grade));
    expect(recommendations, isNotEmpty);
    expect(
      recommendations.every((r) => r.confidence >= 0 && r.confidence <= 100),
      isTrue,
    );
    expect(b.parameters['point'], [1.0, 1.0, 0.0]);
  });

  test(
    'repository toolbar render styles analytics and runtime are explicit',
    () async {
      expect(editor.engine.runtime.isInitialized, isFalse);
      editor.engine.runtime.initialize();
      editor.engine.toolbar.activate(SketchToolType.line);
      expect(editor.engine.toolbar.activeTool, SketchToolType.line);
      expect(
        SketchStylePalette.styles.keys.toSet(),
        SketchVisualState.values.toSet(),
      );
      await editor.engine.persist();
      for (final path in EditorRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(editor.engine.analytics.toJson(), contains('sketchQuality'));
    },
  );

  test('FEL Studio tree inspector factory and bootstrap integrate', () {
    final point = sketch.builders.point.build(const SketchVector(0, 0));
    editor.engine.selection.select(point);
    expect(
      createSketchEditorFelCommands(editor).map((c) => c.name).toSet(),
      hasLength(30),
    );
    final nodes = const SketchEditorStudioAdapter().buildTree(
      sketch,
      constraints,
      editor.engine,
      'project',
    );
    expect(nodes.any((n) => n.name == 'Entities'), isTrue);
    expect(nodes.any((n) => n.name == 'Constraints'), isFalse);
    final section = const PropertyInspector()
        .inspect(nodes.firstWhere((n) => n.id == point.id))
        .firstWhere((s) => s.name == 'Sketch Editor');
    expect(
      section.values.keys,
      containsAll([
        'coordinates',
        'length',
        'radius',
        'diameter',
        'angle',
        'construction',
        'reference',
        'driving',
        'driven',
        'constraintCount',
        'degreesOfFreedom',
        'selectionState',
        'persistentId',
        'history',
        'diagnostics',
      ]),
    );
    final bootstrap = EngineeringBootstrap.instance..initialize();
    expect(bootstrap.services.get<SketchEditorFactory>(), isNotNull);
    expect(bootstrap.services.get<EditorRuntime>(), isNotNull);
    expect(bootstrap.services.get<EditorRepository>(), isNotNull);
    expect(bootstrap.services.get<EditorAnalytics>(), isNotNull);
    expect(bootstrap.services.get<EditorHistory>(), isNotNull);
  });
}
