import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/feature_modeling/analytics/feature_analytics.dart';
import 'package:flcad_mobile/core/feature_modeling/api/feature_modeling_api.dart';
import 'package:flcad_mobile/core/feature_modeling/commands/fel_feature_modeling_commands.dart';
import 'package:flcad_mobile/core/feature_modeling/engine/feature_engine.dart';
import 'package:flcad_mobile/core/feature_modeling/graph/feature_graph.dart';
import 'package:flcad_mobile/core/feature_modeling/history/feature_history.dart';
import 'package:flcad_mobile/core/feature_modeling/integration/feature_modeling_factory.dart';
import 'package:flcad_mobile/core/feature_modeling/integration/feature_studio.dart';
import 'package:flcad_mobile/core/feature_modeling/models/feature_models.dart';
import 'package:flcad_mobile/core/feature_modeling/parameters/feature_parameters.dart';
import 'package:flcad_mobile/core/feature_modeling/repository/feature_repository.dart';
import 'package:flcad_mobile/core/feature_modeling/runtime/feature_runtime.dart';
import 'package:flcad_mobile/core/feature_modeling/validation/feature_validation.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingExecutor implements FeatureExecutor {
  @override
  Future<FeatureResult> execute(
    FeatureInstance feature,
    FeatureContext context,
  ) => throw StateError('execution failed');
}

void main() {
  late Directory project;
  late FeatureModelingApi api;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_features_');
    api = const FeatureModelingFactory().create(
      projectDirectory: project,
      projectId: 'project',
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  test('models all feature contracts without creating geometry', () async {
    final features = [
      for (final type in FeatureType.values) api.builders.of(type).build(),
    ];
    expect(features, hasLength(12));
    expect(features.every((f) => f.result == null), isTrue);
    expect(features.every((f) => !f.definition.supported), isTrue);
    final results = await api.engine.rebuildAll();
    expect(results, hasLength(12));
    expect(
      results.every(
        (r) =>
            !r.success &&
            r.outputs.isEmpty &&
            r.state == FeatureExecutionState.unsupported,
      ),
      isTrue,
    );
    expect(
      api.engine.features.values.every(
        (f) => f.result?.outputs.isEmpty ?? false,
      ),
      isTrue,
    );
  });
  test('1000 features and dependencies retain timeline and impacts', () {
    String? previous;
    for (var i = 0; i < 1000; i++) {
      final f = api.builders
          .of(FeatureType.reference)
          .build(dependencies: [?previous]);
      previous = f.id;
    }
    expect(api.features, hasLength(1000));
    expect(api.engine.timeline.entries, hasLength(1000));
    expect(api.engine.analytics.dependencies, 999);
    expect(
      api.engine.graphs.dependencies.downstream(api.features.first.id),
      hasLength(999),
    );
    expect(
      api.engine.dependencyEngine.upstream(
        api.features.last.id,
        api.engine.graphs,
      ),
      hasLength(999),
    );
  });
  test(
    'circular dependencies are rejected and missing references diagnosed',
    () {
      final graph = DependencyGraph()
        ..add('a')
        ..add('b')
        ..connect('a', 'b');
      expect(() => graph.connect('b', 'a'), throwsStateError);
      api.builders.of(FeatureType.extrude).build(dependencies: ['missing']);
      final validation = api.validate();
      expect(
        validation.issues.map((i) => i.type),
        containsAll([
          FeatureValidationIssueType.brokenDependency,
          FeatureValidationIssueType.unsupportedFeature,
        ]),
      );
    },
  );
  test(
    'suppression freeze undo redo and incremental partial rebuild',
    () async {
      final a = api.builders.of(FeatureType.reference).build(),
          b = api.builders
              .of(FeatureType.reference)
              .build(dependencies: [a.id]);
      api.suppress(a.id);
      expect(a.suppressed, isTrue);
      expect(api.engine.timeline.rebuildQueue, contains(b.id));
      expect(api.engine.undo(), isTrue);
      expect(a.suppressed, isFalse);
      expect(api.engine.redo(), isTrue);
      expect(a.suppressed, isTrue);
      api.unsuppress(a.id);
      api.freeze(b.id);
      final partial = await api.engine.rebuildPartial([a.id]);
      expect(partial, hasLength(1));
      api.unfreeze(b.id);
      api.engine.markDirty(a.id);
      final incremental = await api.engine.rebuildIncremental();
      expect(incremental, hasLength(2));
    },
  );
  test('1000 rebuilds are deterministic and explicitly unavailable', () async {
    final f = api.builders.of(FeatureType.reference).build();
    for (var i = 0; i < 1000; i++) {
      api.engine.markDirty(f.id);
      final result = await api.rebuild();
      expect(result.single.state, FeatureExecutionState.unsupported);
    }
    expect(api.engine.analytics.rebuildCount, 1000);
    expect(api.engine.analytics.failures, 1000);
  });
  test('rebuild failure rolls back execution state', () async {
    final failing = const FeatureModelingFactory().create(
      projectDirectory: project,
      projectId: 'failure',
      executor: _ThrowingExecutor(),
    );
    final f = failing.builders.of(FeatureType.reference).build();
    expect(() => failing.engine.rebuildAll(), throwsStateError);
    await Future<void>.delayed(Duration.zero);
    expect(f.state, FeatureExecutionState.pending);
    expect(failing.engine.analytics.rollbackCount, 1);
    expect(
      failing.engine.history.entries.last.action,
      FeatureHistoryAction.rollback,
    );
  });
  test('parameters formulas units locks and diagnostics are prepared', () {
    api.engine.parameters.define(
      FeatureParameter(
        name: 'width',
        value: 20,
        unit: 'mm',
        mode: FeatureParameterMode.driving,
      ),
    );
    api.engine.parameters.define(
      FeatureParameter(
        name: 'copy',
        expression: 'width',
        unit: 'mm',
        mode: FeatureParameterMode.reference,
      ),
    );
    api.engine.parameters.define(
      FeatureParameter(
        name: 'locked',
        value: 2,
        mode: FeatureParameterMode.locked,
      ),
    );
    expect(api.engine.parameters.resolve('copy'), 20);
    expect(() => api.engine.parameters.set('locked', 3), throwsStateError);
    api.engine.parameters.define(
      FeatureParameter(name: 'futureFormula', expression: 'width * 2'),
    );
    expect(
      api.engine.parameters.validate(),
      contains('Unresolved parameter: futureFormula'),
    );
  });
  test(
    'repository advisor quality Studio FEL runtime factory and bootstrap integrate',
    () async {
      final f = api.builders.of(FeatureType.extrude).build();
      api.validate();
      expect(api.recommendations(), isNotEmpty);
      expect(api.quality().score, inInclusiveRange(0, 100));
      await api.engine.persist();
      for (final path in FeatureRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(
        createFeatureModelingFelCommands(api).map((c) => c.name).toSet(),
        hasLength(35),
      );
      expect(api.engine.runtime.isInitialized, isFalse);
      final node = const FeatureStudioAdapter()
          .buildTree(api.engine, 'project')
          .firstWhere((n) => n.id == f.id);
      final section = const PropertyInspector()
          .inspect(node)
          .firstWhere((s) => s.name == 'Feature Platform');
      expect(
        section.values.keys,
        containsAll([
          'featureType',
          'parameters',
          'references',
          'dependencies',
          'timelinePosition',
          'executionState',
          'suppression',
          'persistentId',
          'diagnostics',
        ]),
      );
      final bootstrap = EngineeringBootstrap.instance..initialize();
      expect(bootstrap.services.get<FeatureModelingFactory>(), isNotNull);
      expect(bootstrap.services.get<FeatureModelingRuntime>(), isNotNull);
      expect(bootstrap.services.get<FeatureRepository>(), isNotNull);
      expect(bootstrap.services.get<FeatureAnalytics>(), isNotNull);
      expect(bootstrap.services.get<FeatureHistory>(), isNotNull);
    },
  );
}
