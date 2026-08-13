import 'dart:io';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/intelligent_sketch/advisor/intent_interpreter.dart';
import 'package:flcad_mobile/core/intelligent_sketch/advisor/sketch_advisor.dart';
import 'package:flcad_mobile/core/intelligent_sketch/analytics/sketch_analytics_engine.dart';
import 'package:flcad_mobile/core/intelligent_sketch/api/sketch_api.dart';
import 'package:flcad_mobile/core/intelligent_sketch/builders/sketch_builder.dart';
import 'package:flcad_mobile/core/intelligent_sketch/constraints/sketch_constraint.dart';
import 'package:flcad_mobile/core/intelligent_sketch/entities/sketch_entity.dart';
import 'package:flcad_mobile/core/intelligent_sketch/engine/sketch_engine.dart';
import 'package:flcad_mobile/core/intelligent_sketch/events/sketch_event.dart';
import 'package:flcad_mobile/core/intelligent_sketch/models/sketch.dart';
import 'package:flcad_mobile/core/intelligent_sketch/models/sketch_context.dart';
import 'package:flcad_mobile/core/intelligent_sketch/models/sketch_dna.dart';
import 'package:flcad_mobile/core/intelligent_sketch/runtime/sketch_runtime.dart';
import 'package:flcad_mobile/core/intelligent_sketch/serialization/sketch_repository.dart';
import 'package:flcad_mobile/core/intelligent_sketch/serialization/sketch_serializer.dart';
import 'package:flcad_mobile/core/intelligent_sketch/solver/adaptive_constraint_solver.dart';
import 'package:flcad_mobile/core/intelligent_sketch/templates/sketch_template.dart';
import 'package:flcad_mobile/core/intelligent_sketch/validators/sketch_validator.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const context = SketchGeometryContext(
  id: 'mesh',
  kind: SketchContextKind.mesh,
  sourceId: 'mesh',
  fingerprint: 'v1',
);
SketchAnchor anchor(double x, double y, [String id = 'mesh']) =>
    SketchAnchor(position: Vec3(x, y, 0), contextId: id);
SketchEntity line(String id, double x, double y) => SketchEntity(
  id: id,
  kind: SketchEntityKind.line,
  mode: SketchEntityMode.live,
  anchors: [anchor(0, 0), anchor(x, y)],
);

void main() {
  test('all entity kinds share an extensible serializable model', () {
    for (final kind in SketchEntityKind.values) {
      final value = SketchEntity(
        id: kind.name,
        kind: kind,
        mode: SketchEntityMode.live,
        anchors: [anchor(0, 0)],
        parameters: const {'radius': 1},
      );
      expect(SketchEntity.fromJson(value.toJson()).kind, kind);
    }
  });
  test('builder validates primitives and analytics calculates profiles', () {
    const builder = DefaultSketchEntityBuilder();
    final circle = builder.build(
      SketchEntityRecipe(
        SketchEntityKind.circle,
        [anchor(0, 0)],
        parameters: const {'radius': 2},
      ),
    );
    final analytics = const SketchAnalyticsEngine().evaluate([circle]);
    expect(analytics.area, closeTo(4 * 3.1415926535, 1e-6));
    expect(analytics.closed, isTrue);
    expect(
      () => builder.build(
        SketchEntityRecipe(SketchEntityKind.circle, [anchor(0, 0)]),
      ),
      throwsArgumentError,
    );
  });
  test('ACS corrects geometry, reports DOF and redundant constraints', () {
    final constraints = [
      const SketchConstraint(
        id: 'h1',
        type: SketchConstraintType.horizontal,
        entityIds: ['a'],
      ),
      const SketchConstraint(
        id: 'h2',
        type: SketchConstraintType.horizontal,
        entityIds: ['a'],
      ),
    ];
    final result = AdaptiveConstraintSolver().solve([
      line('a', 2, 1),
    ], constraints);
    expect(result.entities.single.anchors.last.position.y, 0);
    expect(result.diagnostics.last.state, ConstraintState.redundant);
    expect(result.remainingDegreesOfFreedom, greaterThan(0));
  });
  test('surface constraints remain explicit extension points', () {
    final result = AdaptiveConstraintSolver().solve(
      [line('a', 1, 0)],
      [
        const SketchConstraint(
          id: 's',
          type: SketchConstraintType.onSurface,
          entityIds: ['a'],
        ),
      ],
    );
    expect(result.diagnostics.single.state, ConstraintState.unsupported);
    expect(result.converged, isFalse);
  });
  test('ACS explains conflicting dimensions', () {
    final result = AdaptiveConstraintSolver().solve(
      [line('a', 1, 0)],
      const [
        SketchConstraint(
          id: 'd1',
          type: SketchConstraintType.distance,
          entityIds: ['a'],
          parameters: {'distance': 1},
        ),
        SketchConstraint(
          id: 'd2',
          type: SketchConstraintType.distance,
          entityIds: ['a'],
          parameters: {'distance': 2},
        ),
      ],
    );
    expect(result.overConstrained, isTrue);
    expect(result.diagnostics.last.suggestion, isNotNull);
  });
  test(
    'DNA, serialization, validation and hybrid context survive round trip',
    () {
      final now = DateTime.utc(2026),
          entities = [line('a', 1, 0)],
          contexts = [
            context,
            const SketchGeometryContext(
              id: 'surface',
              kind: SketchContextKind.surface,
              sourceId: 'surface',
              fingerprint: 'v2',
            ),
          ],
          dna = createSketchDNA(contexts, entities),
          analytics = const SketchAnalyticsEngine().evaluate(entities),
          sketch = IntelligentSketch(
            id: 's',
            projectId: 'p',
            name: 'Hybrid',
            mode: SketchMode.live,
            status: SketchStatus.created,
            contexts: contexts,
            entities: entities,
            constraints: const [],
            dna: dna,
            analytics: analytics,
            version: 1,
            createdAt: now,
            updatedAt: now,
          );
      final restored = SketchSerializer.fromJson(
        SketchSerializer.toJson(sketch),
      );
      expect(restored.contexts, hasLength(2));
      expect(restored.dna.hash, dna.hash);
      expect(const SketchValidator().validate(restored), isEmpty);
    },
  );
  test(
    'advisor, recognizer intent and template library foundations work',
    () async {
      final now = DateTime.now(),
          circle = const DefaultSketchEntityBuilder().build(
            SketchEntityRecipe(
              SketchEntityKind.circle,
              [SketchAnchor(position: Vec3(0, 0, 0), contextId: 'mesh')],
              parameters: {'radius': 1},
            ),
          ),
          sketch = IntelligentSketch(
            id: 's',
            projectId: 'p',
            name: 'Circle',
            mode: SketchMode.live,
            status: SketchStatus.created,
            contexts: const [context],
            entities: [circle],
            constraints: const [],
            dna: createSketchDNA(const [context], [circle]),
            analytics: const SketchAnalyticsEngine().evaluate([circle]),
            version: 1,
            createdAt: now,
            updatedAt: now,
          );
      expect(
        (await const RuleBasedSketchAdvisor().advise(sketch)).first.code,
        'create-cylinder',
      );
      expect(
        const IntentInterpreter().interpret(sketch).kind,
        'closed-profile',
      );
      final library = InMemorySketchLibrary();
      await library.save(
        SketchTemplate(
          id: 't',
          name: 'Corporate',
          entities: [circle],
          constraints: const [],
          corporate: true,
        ),
      );
      expect(await library.find('t'), isNotNull);
    },
  );
  test('solver runs in background isolate', () async {
    final result = await const IsolateSketchRuntime().solve(
      [line('a', 2, 1)],
      [
        const SketchConstraint(
          id: 'h',
          type: SketchConstraintType.horizontal,
          entityIds: ['a'],
        ),
      ],
    );
    expect(result.converged, isTrue);
  });
  test('FEL exposes procedural Sketch commands', () {
    final registry = createNativeCommandRegistry();
    for (final name in [
      'CREATE SKETCH',
      'CREATE CENTER',
      'CREATE CIRCLE',
      'APPLY CONSTRAINTS',
      'PROJECT SURFACE',
      'CREATE PROFILE',
      'DELETE SKETCH',
    ]) {
      expect(registry.find(name), isNotNull);
    }
  });
  test(
    'API persists Project First graph, constraints, snapshots and events',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad_sketch_');
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
            storage: LocalStorageService(rootDirectory: root),
          ),
          project = await projects.create(name: 'Part', client: 'Client'),
          repository = SketchRepository(projects: projects),
          events = SketchEventBus(),
          captured = <SketchEvent>[];
      events.subscribe(captured.add);
      final api = SketchApi(
        engine: SketchEngine(repository: repository, events: events),
      );
      final sketch = await api.create(
        projectId: project.id,
        name: 'Hybrid',
        mode: SketchMode.live,
        contexts: const [context],
        entities: [line('a', 1, 1)],
        constraints: const [
          SketchConstraint(
            id: 'h',
            type: SketchConstraintType.horizontal,
            entityIds: ['a'],
          ),
        ],
      );
      final solved = await api.solve(sketch);
      expect(solved.entities.single.anchors.last.position.y, 0);
      await api.snapshot(solved, 'v1');
      expect((await api.list(project.id)).single.version, 2);
      final directory = await projects.directoryFor(project.id);
      for (final name in [
        'sketches.json',
        'sketch_graph.json',
        'sketch_history.json',
        'constraints.json',
        'Snapshots/v1.json',
      ]) {
        expect(await File('${directory.path}/Sketch/$name').exists(), isTrue);
      }
      expect(
        captured.map((e) => e.type),
        containsAll([SketchEventType.created, SketchEventType.solved]),
      );
    },
  );
}
