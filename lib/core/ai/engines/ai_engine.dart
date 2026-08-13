import '../cache/ai_cache.dart';
import '../models/ai_context.dart';
import '../models/ai_result.dart';
import '../plugins/plugin_manager.dart';
import '../services/ai_benchmark_service.dart';

class AIEngine {
  AIEngine({
    PluginManager? plugins,
    AICache? cache,
    AIBenchmarkService? benchmark,
  }) : plugins = plugins ?? PluginManager(),
       cache = cache ?? AICache(),
       benchmark = benchmark ?? AIBenchmarkService();
  final PluginManager plugins;
  final AICache cache;
  final AIBenchmarkService benchmark;

  Future<AIResult> execute(
    AIContext context, {
    AICancellationToken? cancellation,
  }) async {
    if (cancellation?.isCancelled == true) throw const AIExecutionCancelled();
    final candidates =
        plugins.plugins
            .where((plugin) => plugin.supports(context.task))
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
    if (candidates.isEmpty) {
      throw StateError('Nenhum plugin suporta ${context.task.name}');
    }
    Object? lastError;
    for (final plugin in candidates) {
      final cached = await cache.read(context, plugin.id);
      if (cached != null) return cached;
      final watch = Stopwatch()..start();
      try {
        final result = await plugin.execute(context);
        if (cancellation?.isCancelled == true) {
          throw const AIExecutionCancelled();
        }
        watch.stop();
        benchmark.record(
          pluginId: plugin.id,
          task: context.task.name,
          duration: watch.elapsed,
        );
        await cache.write(context, result);
        return result;
      } on AIExecutionCancelled {
        rethrow;
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Todos os plugins falharam: $lastError');
  }
}

class AICancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class AIExecutionCancelled implements Exception {
  const AIExecutionCancelled();
}
