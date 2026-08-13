import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/engineering/cache/engineering_cache.dart';
import 'package:flcad_mobile/core/engineering/plugins/plugin_registry.dart';
import 'package:flcad_mobile/core/engineering/runtime/engineering_runtime.dart';
import 'package:flcad_mobile/core/engineering/serialization/engineering_envelope.dart';
import 'package:flcad_mobile/core/engineering/serialization/migration_engine.dart';
import 'package:flcad_mobile/core/engineering/serialization/schema_registry.dart';
import 'package:flcad_mobile/core/engineering/services/engineering_service_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Runtime 2.0 prioritizes, pauses, reports metrics and cancels namespaces',
    () async {
      final runtime = EngineeringRuntime(workerCount: 1);
      runtime.pause();
      final low = runtime.submit(
        'low',
        () => 'low',
        priority: EngineeringTaskPriority.low,
      );
      final high = runtime.submit(
        'high',
        () => 'high',
        priority: EngineeringTaskPriority.high,
      );
      expect(runtime.queuedTaskIds, ['high', 'low']);
      runtime.resume();
      expect(await high.future, 'high');
      expect(await low.future, 'low');
      expect(runtime.metrics.completed, 2);
      await runtime.dispose();
    },
  );

  test('Engineering Cache validates fingerprints, versions and statistics', () {
    final cache = EngineeringCache();
    cache.put(
      EngineeringCacheNamespaces.geometry,
      'mesh',
      4,
      fingerprint: 'a',
      version: 2,
    );
    expect(cache.get<int>('geometry', 'mesh', fingerprint: 'a', version: 2), 4);
    expect(cache.get<int>('geometry', 'mesh', fingerprint: 'b'), isNull);
    expect(cache.statistics.hits, 1);
    expect(cache.statistics.evictions, 1);
  });

  test('Schema Registry migrates and validates envelopes', () {
    final registry = SchemaRegistry()
      ..register(
        EngineeringSchema(
          name: 'part',
          currentVersion: 2,
          validator: (value) =>
              value['name'] is String ? const [] : const ['name'],
        ),
      )
      ..registerMigration(
        'part',
        1,
        (value) => {...value, 'name': value['label']},
      );
    final migrated = MigrationEngine(registry).migrate(
      EngineeringEnvelope(
        schema: 'part',
        version: 1,
        projectId: 'p',
        payload: const {'label': 'housing'},
        createdAt: DateTime.utc(2026),
      ),
    );
    expect(migrated.version, 2);
    expect(migrated.payload['name'], 'housing');
  });

  test('DI factories are lazy and bootstrap owns concrete composition', () {
    final registry = EngineeringServiceRegistry();
    var calls = 0;
    registry.registerFactory<String>((_) {
      calls++;
      return 'service';
    });
    expect(calls, 0);
    expect(registry.get<String>(), 'service');
    expect(registry.get<String>(), 'service');
    expect(calls, 1);
    final context = EngineeringBootstrap.instance.createContext('project');
    expect(context.projectId, 'project');
    expect(context.runtime, same(EngineeringBootstrap.instance.runtime));
  });

  test('Plugin registry enforces dependency lifecycle', () async {
    final registry = EngineeringPluginRegistry();
    final base = _Plugin('base'),
        dependent = _Plugin('dependent', dependencies: const {'base': '^1'});
    registry
      ..register(base)
      ..register(dependent);
    expect(() => registry.activate('dependent'), throwsA(isA<StateError>()));
    await registry.activate('base');
    await registry.activate('dependent');
    expect(registry.stateOf('dependent'), EngineeringPluginState.active);
    await registry.deactivate('dependent');
    expect(registry.stateOf('dependent'), EngineeringPluginState.stopped);
  });
}

class _Plugin implements EngineeringPlugin {
  _Plugin(this.id, {this.dependencies = const {}});
  final String id;
  final Map<String, String> dependencies;
  @override
  EngineeringPluginDescriptor get descriptor => EngineeringPluginDescriptor(
    id: id,
    version: '1.0.0',
    dependencies: dependencies,
  );
  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}
