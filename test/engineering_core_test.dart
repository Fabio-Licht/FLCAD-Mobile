import 'package:flcad_mobile/core/engineering/api/engineering_platform_bus.dart';
import 'package:flcad_mobile/core/engineering/benchmark/engineering_benchmark.dart';
import 'package:flcad_mobile/core/engineering/cache/engineering_cache.dart';
import 'package:flcad_mobile/core/engineering/commands/engineering_command_bus.dart';
import 'package:flcad_mobile/core/engineering/context/engineering_context.dart';
import 'package:flcad_mobile/core/engineering/dna/engineering_dna.dart';
import 'package:flcad_mobile/core/engineering/events/engineering_event_bus.dart';
import 'package:flcad_mobile/core/engineering/graph/engineering_graph.dart';
import 'package:flcad_mobile/core/engineering/history/engineering_history.dart';
import 'package:flcad_mobile/core/engineering/knowledge/engineering_knowledge_bus.dart';
import 'package:flcad_mobile/core/engineering/metrics/engineering_metrics.dart';
import 'package:flcad_mobile/core/engineering/queries/engineering_query_bus.dart';
import 'package:flcad_mobile/core/engineering/runtime/engineering_runtime.dart';
import 'package:flcad_mobile/core/engineering/serialization/engineering_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

class AddCommand implements EngineeringCommand<int> {
  const AddCommand(this.projectId, this.value);
  @override
  final String projectId;
  final int value;
  @override
  String get name => 'add';
  @override
  Map<String, dynamic> get auditData => {'value': value};
}

class ValueQuery implements EngineeringQuery<int> {
  const ValueQuery(this.projectId);
  @override
  final String projectId;
  @override
  String get name => 'value';
}

void main() {
  test('Engineering DNA is deterministic and namespaced cache tracks hits', () {
    final a = StandardEngineeringDNA.create('feature', const {'b': 2, 'a': 1}),
        b = StandardEngineeringDNA.create('feature', const {'a': 1, 'b': 2}),
        cache = EngineeringCache();
    expect(a.hash, b.hash);
    cache.put('feature', a.hash, 42);
    expect(cache.get<int>('feature', a.hash), 42);
    expect(cache.hitRate, 1);
    cache.invalidateNamespace('feature');
    expect(cache.length, 0);
  });
  test('event bus filters, prioritizes, replays and cancels', () async {
    final bus = EngineeringEventBus(), order = <String>[];
    bus.subscribe(
      (_) => order.add('low'),
      priority: EngineeringEventPriority.low,
    );
    final subscription = bus.subscribe(
      (_) => order.add('high'),
      filter: (e) => e.domain == 'sketch',
      priority: EngineeringEventPriority.high,
    );
    final event = EngineeringEvent(
      id: 'e',
      projectId: 'p',
      domain: 'sketch',
      type: 'created',
      entityId: 's',
      timestamp: DateTime.now(),
    );
    await bus.publish(event);
    expect(order, ['high', 'low']);
    subscription.cancel();
    await bus.publish(event);
    expect(order.last, 'low');
    expect(bus.query(domain: 'sketch'), hasLength(2));
  });
  test('command and query buses provide CQRS and audit', () async {
    final events = EngineeringEventBus(), audits = <EngineeringEvent>[];
    events.subscribe(audits.add);
    final commands = EngineeringCommandBus(events: events),
        queries = EngineeringQueryBus();
    var value = 0;
    commands.register<int>((command) async {
      final add = command as AddCommand, previous = value;
      value += add.value;
      return EngineeringCommandResult(
        value,
        undo: () async => value = previous,
      );
    });
    queries.register<int>((_) async => value);
    expect((await commands.execute<int>(const AddCommand('p', 3))).value, 3);
    expect(await queries.execute<int>(const ValueQuery('p')), 3);
    await commands.undo();
    expect(value, 0);
    expect(audits.single.domain, 'command');
  });
  test('history, graph, knowledge and context share project scope', () async {
    final history = EngineeringHistory()
          ..record(
            projectId: 'p',
            entityId: 'r',
            domain: 'region',
            action: 'create',
            snapshot: 1,
          ),
        graph = EngineeringGraph()
          ..addNode(const EngineeringGraphNode('r', EngineeringNodeType.region))
          ..addNode(
            const EngineeringGraphNode('s', EngineeringNodeType.surface),
          );
    graph.connect(const EngineeringGraphEdge('r', 's', 'drives'));
    expect(history.replay<int>('r', 1), 1);
    expect(graph.impact('r'), {'s'});
    final knowledge = EngineeringKnowledgeBus()
      ..register(
        (p, id) async => EngineeringKnowledge(
          p,
          id,
          const {'quality': 1},
          const [],
          const ['test'],
        ),
      );
    expect(await knowledge.resolve('p', 'r'), hasLength(1));
    expect(EngineeringContext.standard('p').projectId, 'p');
  });
  test(
    'runtime cancellation, benchmark, envelope and EPB foundations work',
    () async {
      final runtime = EngineeringRuntime(),
          task = runtime.submit<int>('sum', () => 1 + 2);
      expect(await task.future, 3);
      final metrics = EngineeringMetrics(),
          result = await EngineeringBenchmark(metrics).run('noop', () {});
      expect(result.success, isTrue);
      expect(metrics.query('benchmark.elapsed'), isNotEmpty);
      final envelope = EngineeringEnvelope(
        schema: 'test',
        version: 1,
        projectId: 'p',
        payload: const {'ok': true},
        createdAt: DateTime.utc(2026),
      );
      expect(
        EngineeringEnvelope.fromJson(envelope.toJson()).payload['ok'],
        isTrue,
      );
      final epb = EngineeringPlatformBus();
      expect(epb.events, isNotNull);
    },
  );
}
