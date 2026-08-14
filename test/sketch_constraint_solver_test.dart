import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/sketch_constraints/analytics/constraint_analytics.dart';
import 'package:flcad_mobile/core/sketch_constraints/api/constraint_api.dart';
import 'package:flcad_mobile/core/sketch_constraints/commands/fel_constraint_commands.dart';
import 'package:flcad_mobile/core/sketch_constraints/diagnostics/constraint_diagnostics.dart';
import 'package:flcad_mobile/core/sketch_constraints/graph/constraint_graph.dart';
import 'package:flcad_mobile/core/sketch_constraints/history/constraint_history.dart';
import 'package:flcad_mobile/core/sketch_constraints/integration/constraint_factory.dart';
import 'package:flcad_mobile/core/sketch_constraints/integration/constraint_selection.dart';
import 'package:flcad_mobile/core/sketch_constraints/integration/constraint_studio.dart';
import 'package:flcad_mobile/core/sketch_constraints/models/constraint_models.dart';
import 'package:flcad_mobile/core/sketch_constraints/repository/constraint_repository.dart';
import 'package:flcad_mobile/core/sketch_constraints/runtime/constraint_runtime.dart';
import 'package:flcad_mobile/core/sketch_engine/api/sketch_engine_api.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;
  late SketchEngineApi sketch;
  late ConstraintApi api;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_constraints_');
    sketch = const SketchEngineFactory().create(project)
      ..createSketch('Parametric');
    api = const ConstraintFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test(
    'solver applies horizontal, coincident and incremental dirty solve',
    () async {
      final line = sketch.builders.line.build(
        const SketchVector(0, 0),
        const SketchVector(4, 3),
      );
      final a = sketch.builders.point.build(const SketchVector(1, 2));
      final b = sketch.builders.point.build(const SketchVector(9, 9));
      final horizontal = api.builders.horizontal.build([line.id], priority: 10);
      final coincident = api.builders.coincident.build([a.id, b.id]);
      final result = await api.solve();
      expect(result.solvedIds, containsAll([horizontal.id, coincident.id]));
      expect(line.parameters['end'], [4.0, 0.0, 0.0]);
      expect(b.parameters['point'], a.parameters['point']);
      api.engine.solver.markDirty(
        horizontal.id,
        api.engine.graphs.dependencies,
      );
      final partial = await api.solve(only: [horizontal.id]);
      expect(partial.statistics.iterations, 1);
      expect(api.engine.solver.dirty, isNot(contains(horizontal.id)));
    },
  );

  test(
    'detects missing references, overdefinition and duplicate constraints',
    () async {
      final line = sketch.builders.line.build(
        const SketchVector(0, 0),
        const SketchVector(1, 1),
      );
      api.builders.horizontal.build([line.id]);
      api.builders.vertical.build([line.id]);
      api.builders.radius.build(['missing'], value: 2);
      api.builders.distance.build([line.id], value: 2, priority: 2);
      api.builders.distance.build([line.id], value: 3, priority: 1);
      final result = await api.solve();
      expect(
        result.diagnostics.map((d) => d.kind),
        containsAll([
          ConstraintDiagnosticKind.overConstraint,
          ConstraintDiagnosticKind.missingReference,
          ConstraintDiagnosticKind.conflict,
        ]),
      );
      expect(() => api.builders.horizontal.build([line.id]), throwsStateError);
      expect(api.engine.constraints, hasLength(5));
    },
  );

  test('constraint dependency graph rejects circular dependencies', () {
    final graph = ConstraintDependencyGraph()
      ..addNode('a')
      ..addNode('b')
      ..connect('a', 'b');
    expect(() => graph.connect('b', 'a'), throwsStateError);
  });

  test('transaction rollback and undo redo are atomic', () {
    final point = sketch.builders.point.build(const SketchVector(0, 0));
    final first = api.builders.of(SketchConstraintType.fixed).build([point.id]);
    expect(api.engine.undo(), isTrue);
    expect(api.engine.constraints, isEmpty);
    expect(api.engine.redo(), isTrue);
    expect(api.engine.constraints, contains(first.id));
    final count = api.engine.history.entries.length;
    expect(
      () => api.engine.transaction('bad', () {
        api.builders.radius.build([point.id], value: 2);
        throw StateError('rollback');
      }),
      throwsStateError,
    );
    expect(api.engine.constraints, hasLength(1));
    expect(api.engine.history.entries.length, count + 1);
    expect(
      api.engine.history.entries.last.action,
      ConstraintHistoryAction.rollback,
    );
  });

  test('handles 1000 constraints deterministically', () async {
    for (var i = 0; i < 1000; i++) {
      final point = sketch.builders.point.build(SketchVector(i.toDouble(), 0));
      api.builders.of(SketchConstraintType.fixed).build([point.id]);
    }
    final result = await api.solve();
    expect(api.constraints, hasLength(1000));
    expect(result.statistics.iterations, 1000);
    expect(result.solvedIds, hasLength(1000));
    expect(api.engine.analytics.totalConstraints, 1000);
  });

  test('underdefined sketch is diagnosed', () async {
    sketch.builders.point.build(const SketchVector(0, 0));
    sketch.builders.point.build(const SketchVector(1, 1));
    final c = api.builders.of(SketchConstraintType.fixed).build([
      sketch.engine.entities.keys.first,
    ]);
    final result = await api.solve();
    expect(
      result.diagnostics.map((d) => d.kind),
      contains(ConstraintDiagnosticKind.underConstraint),
    );
    expect(c.status, ConstraintStatus.satisfied);
  });

  test(
    'repository persists constraints dimensions graphs history and analytics',
    () async {
      final point = sketch.builders.point.build(const SketchVector(0, 0));
      final constraint = api.builders.distance.build([point.id], value: 3);
      api.engine.addDimension(
        SketchDimension(
          type: SketchDimensionType.linear,
          constraintId: constraint.id,
          value: 3,
        ),
      );
      await api.engine.persist();
      for (final path in ConstraintRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      final loaded = const ConstraintFactory().create(
        projectDirectory: project,
        sketch: sketch,
      );
      await loaded.engine.load();
      expect(loaded.constraints.single.id, constraint.id);
      expect(loaded.engine.dimensions, hasLength(1));
    },
  );

  test(
    'selection FEL Studio inspector runtime factory and bootstrap integrate',
    () {
      final point = sketch.builders.point.build(const SketchVector(0, 0));
      final constraint = api.builders.of(SketchConstraintType.fixed).build([
        point.id,
      ]);
      final selection = ConstraintSelection()
        ..selectConstraint(constraint.id)
        ..highlightConflict([constraint.id])
        ..preview(constraint.id);
      expect(selection.selectedConstraints, contains(constraint.id));
      expect(
        createConstraintFelCommands(api).map((c) => c.name).toSet(),
        hasLength(25),
      );
      final node = const ConstraintStudioAdapter()
          .buildTree(api.engine, 'project')
          .firstWhere((n) => n.id == constraint.id);
      final section = const PropertyInspector()
          .inspect(node)
          .firstWhere((s) => s.name == 'Constraint');
      expect(
        section.values.keys,
        containsAll([
          'constraintType',
          'status',
          'driving',
          'driven',
          'priority',
          'solved',
          'references',
          'diagnostics',
          'timestamp',
          'persistentId',
        ]),
      );
      final runtime = ConstraintRuntime();
      expect(runtime.isInitialized, isFalse);
      runtime.initialize();
      expect(runtime.isInitialized, isTrue);
      final bootstrap = EngineeringBootstrap.instance..initialize();
      expect(bootstrap.services.get<ConstraintFactory>(), isNotNull);
      expect(bootstrap.services.get<ConstraintRuntime>(), isNotNull);
      expect(bootstrap.services.get<ConstraintRepository>(), isNotNull);
      expect(bootstrap.services.get<ConstraintAnalytics>(), isNotNull);
      expect(bootstrap.services.get<ConstraintHistory>(), isNotNull);
    },
  );
}
