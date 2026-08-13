import 'dart:io';

import 'package:flcad_mobile/core/ai/engines/ai_engine.dart';
import 'package:flcad_mobile/core/ai/models/ai_context.dart';
import 'package:flcad_mobile/core/ai/models/ai_result.dart';
import 'package:flcad_mobile/core/ai/models/ai_task.dart';
import 'package:flcad_mobile/core/ai/plugins/ai_plugin.dart';
import 'package:flcad_mobile/core/ai/plugins/plugin_manager.dart';
import 'package:flcad_mobile/core/ai/providers/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late AIContext context;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_ai_');
    context = AIContext(
      projectId: 'project',
      projectPath: root.path,
      task: AITask.captureQuality,
      input: const {},
      fingerprint: 'same-input',
    );
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'selects highest priority plugin and caches unchanged inference',
    () async {
      final preferred = _Plugin('preferred', priority: 10);
      final fallback = _Plugin('fallback');
      final engine = AIEngine()
        ..plugins.register(fallback)
        ..plugins.register(preferred);
      final first = await engine.execute(context);
      final second = await engine.execute(context);
      expect(first.pluginId, 'preferred');
      expect(second.fromCache, isTrue);
      expect(preferred.executions, 1);
      expect(engine.benchmark.metrics, hasLength(1));
    },
  );

  test('falls back when the preferred plugin fails', () async {
    final engine = AIEngine()
      ..plugins.register(_Plugin('fallback'))
      ..plugins.register(_Plugin('broken', priority: 20, fails: true));
    expect((await engine.execute(context)).pluginId, 'fallback');
  });

  test('supports cancellation and parallel execution', () async {
    final engine = AIEngine()..plugins.register(_Plugin('parallel'));
    final token = AICancellationToken()..cancel();
    await expectLater(
      engine.execute(context, cancellation: token),
      throwsA(isA<AIExecutionCancelled>()),
    );
    final results = await Future.wait([
      engine.execute(
        AIContext(
          projectId: 'project',
          projectPath: root.path,
          task: AITask.captureQuality,
          input: const {},
          fingerprint: 'a',
        ),
      ),
      engine.execute(
        AIContext(
          projectId: 'project',
          projectPath: root.path,
          task: AITask.captureQuality,
          input: const {},
          fingerprint: 'b',
        ),
      ),
    ]);
    expect(results, hasLength(2));
  });

  test('plugin manager supports provider registration and hot swap', () {
    final manager = PluginManager();
    manager.register(_Plugin('one'));
    manager.registerProvider(MockProvider());
    expect(manager.find('one'), isNotNull);
    expect(manager.providers.single.id, 'mock');
    expect(manager.unload('one')?.id, 'one');
  });
}

class _Plugin extends AIPlugin {
  _Plugin(this.id, {this.priority = 0, this.fails = false});
  @override
  final String id;
  @override
  String get name => id;
  @override
  String get version => '1';
  @override
  final int priority;
  final bool fails;
  int executions = 0;
  @override
  bool supports(AITask task) => task == AITask.captureQuality;
  @override
  Future<AIResult> execute(AIContext context) async {
    executions++;
    if (fails) throw StateError('expected');
    return AIResult(
      pluginId: id,
      task: context.task.name,
      score: 90,
      confidence: .8,
      data: const {},
      recommendations: const [],
      createdAt: DateTime.now(),
    );
  }
}
