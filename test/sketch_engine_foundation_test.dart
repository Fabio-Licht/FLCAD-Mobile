import 'dart:io';

import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/app/engineering_bridge/adapters/sketch_bridge.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/fel/commands/fel_command.dart';
import 'package:flcad_mobile/core/sketch_engine/analytics/sketch_analytics.dart';
import 'package:flcad_mobile/core/sketch_engine/api/sketch_engine_api.dart';
import 'package:flcad_mobile/core/sketch_engine/commands/fel_sketch_engine_commands.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/graph/sketch_graph.dart';
import 'package:flcad_mobile/core/sketch_engine/history/sketch_history.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_studio.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flcad_mobile/core/sketch_engine/repository/sketch_repository.dart';
import 'package:flcad_mobile/core/sketch_engine/runtime/sketch_runtime.dart';
import 'package:flcad_mobile/core/sketch_engine/selection/sketch_selection_engine.dart';
import 'package:flcad_mobile/core/sketch_engine/snapping/sketch_snapping.dart';
import 'package:flcad_mobile/core/reference_engine/models/reference_geometry.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;
  late SketchEngineApi api;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_sketch_');
    api = const SketchEngineFactory().create(project);
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('creates all parametric entities, graphs and analytics', () {
    final sketch = api.createSketch('Foundation');
    final entities = <SketchEntity>[
      api.builders.point.build(const SketchVector(1, 2)),
      api.builders.line.build(
        const SketchVector(0, 0),
        const SketchVector(1, 1),
      ),
      api.builders.circle.build(const SketchVector(0, 0), 2),
      api.builders.arc.build(const SketchVector(0, 0), 2, 0, 1),
      api.builders.spline.build(const [SketchVector(0, 0), SketchVector(1, 2)]),
      api.builders.ellipse.build(const SketchVector(0, 0), 2, 1),
      api.builders.construction.build({'kind': 'axis'}),
      api.builders.reference.build({'source': 'edge:1'}),
    ];
    expect(sketch.entityIds, hasLength(8));
    expect(entities.map((e) => e.id).toSet(), hasLength(8));
    expect(api.engine.graphs.entities.nodes, hasLength(8));
    expect(api.engine.analytics.entities, 8);
    expect(api.engine.analytics.constructionRatio, 1 / 8);
    expect(api.engine.analytics.referenceRatio, 1 / 8);
  });

  test('opens Sketch on world supports without any Mesh context', () {
    final bridge = SketchBridge(api);
    final supports = <SketchPlaneType, PlaneGeometry>{
      SketchPlaneType.xy: const PlaneGeometry(
        Vec3(0, 0, 0),
        Vec3(0, 0, 1),
        xDirection: Vec3(1, 0, 0),
      ),
      SketchPlaneType.yz: const PlaneGeometry(
        Vec3(0, 0, 0),
        Vec3(1, 0, 0),
        xDirection: Vec3(0, 1, 0),
      ),
      SketchPlaneType.zx: const PlaneGeometry(
        Vec3(0, 0, 0),
        Vec3(0, 1, 0),
        xDirection: Vec3(1, 0, 0),
      ),
    };

    for (final entry in supports.entries) {
      final sketch = bridge.openOnSupport(
        referenceId: 'world:${entry.key.name}',
        geometry: entry.value,
        name: '${entry.key.name.toUpperCase()} Sketch',
        planeType: entry.key,
      );
      expect(sketch.plane.type, entry.key);
      expect(sketch.plane.parameters['referenceId'], 'world:${entry.key.name}');
    }

    expect(api.sketches, hasLength(3));
  });

  test('transaction rollback is atomic and undo redo preserve entities', () {
    api.createSketch('Atomic');
    final point = api.builders.point.build(const SketchVector(0, 0));
    expect(api.engine.undo(), isTrue);
    expect(api.engine.entities, isEmpty);
    expect(api.engine.redo(), isTrue);
    expect(api.engine.entities, contains(point.id));
    final historyLength = api.engine.history.entries.length;
    expect(
      () => api.engine.transaction('failure', () {
        api.builders.line.build(
          const SketchVector(0, 0),
          const SketchVector(1, 1),
        );
        throw StateError('rollback');
      }),
      throwsStateError,
    );
    expect(api.engine.entities, hasLength(1));
    expect(api.engine.history.entries, hasLength(historyLength));
  });

  test('repository persists project-first directories and reloads', () async {
    api.createSketch('Persisted');
    api.builders.point.build(const SketchVector(4, 5));
    await api.engine.persist();
    for (final path in SketchRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    final loaded = const SketchEngineFactory().create(project);
    await loaded.engine.load();
    expect(loaded.sketches.single.name, 'Persisted');
    expect(loaded.engine.entities.values.single, isA<SketchPoint>());
  });

  test('selection filters, priority and snapping architecture work', () {
    api.createSketch('Selection');
    final point = api.builders.point.build(const SketchVector(0, 0));
    final reference = api.builders.reference.build({'layer': 'refs'});
    api.engine.selection.select(point);
    expect(api.engine.selection.selected, contains(point.id));
    expect(
      api.engine.selection.window(
        api.engine.entities.values,
        const SketchSelectionFilter(reference: true),
      ),
      [reference],
    );
    expect(
      api.engine.selection.priority(
        [reference, point],
        const {SketchEntityType.point: 10},
      ),
      point,
    );
    expect(
      const SketchSnapSettings(
        enabled: {SketchSnapType.grid, SketchSnapType.endpoint},
        priority: {SketchSnapType.grid: 2},
      ).ordered().first,
      SketchSnapType.grid,
    );
  });

  test('coordinate systems, planes and independent graph are parametric', () {
    final cs = const SketchCoordinateSystem().translate(
      const SketchVector(2, 3),
    );
    expect(cs.localToGlobal(const SketchVector(1, 1)).toJson(), [3, 4, 0]);
    expect(cs.globalToLocal(const SketchVector(3, 4)).toJson(), [1, 1, 0]);
    expect(SketchPlaneType.values, hasLength(9));
    final graph = DependencyGraph()
      ..addNode('a')
      ..addNode('b')
      ..connect('a', 'b');
    expect(() => graph.connect('b', 'a'), throwsStateError);
  });

  test('FEL exposes twenty commands and Studio inspector fields', () {
    final commands = createSketchEngineFelCommands(api);
    expect(commands.map((e) => e.name).toSet(), hasLength(20));
    final registry = FELCommandRegistry();
    for (final command in commands) {
      registry.register(command);
    }
    expect(registry.find('CREATE POINT'), isNotNull);
    api.createSketch('Studio');
    api.builders.point.build(const SketchVector(0, 0));
    final nodes = const SketchStudioAdapter().buildTree(api.engine, 'project');
    final entity = nodes.firstWhere((n) => n.context['entityType'] == 'point');
    final sketchSection = const PropertyInspector()
        .inspect(entity)
        .firstWhere((s) => s.name == 'Sketch');
    expect(
      sketchSection.values.keys,
      containsAll([
        'persistentId',
        'entityType',
        'coordinates',
        'visibility',
        'lock',
        'diagnostics',
      ]),
    );
  });

  test('runtime is explicit and bootstrap registers foundation services', () {
    final runtime = SketchRuntime();
    expect(runtime.isRunning, isFalse);
    runtime.initialize();
    expect(runtime.isRunning, isTrue);
    runtime.shutdown();
    final bootstrap = EngineeringBootstrap.instance..initialize();
    expect(bootstrap.services.get<SketchRuntime>(), isNotNull);
    expect(bootstrap.services.get<SketchEngineFactory>(), isNotNull);
    expect(bootstrap.services.get<SketchAnalytics>(), isNotNull);
    expect(bootstrap.services.get<SketchHistory>(), isNotNull);
    expect(bootstrap.services.get<SketchRepository>(), isNotNull);
  });
}
