import 'dart:io';

class AIBenchmark {
  const AIBenchmark({
    required this.pluginId,
    required this.task,
    required this.durationMs,
    required this.cpuCores,
    required this.ramBytes,
    required this.timestamp,
  });
  final String pluginId;
  final String task;
  final int durationMs;
  final int cpuCores;
  final int ramBytes;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'task': task,
    'durationMs': durationMs,
    'cpuCores': cpuCores,
    'ramBytes': ramBytes,
    'timestamp': timestamp.toIso8601String(),
    'gpu': null,
    'temperature': null,
    'battery': null,
  };
}

class AIBenchmarkService {
  final List<AIBenchmark> _metrics = [];
  List<AIBenchmark> get metrics => List.unmodifiable(_metrics);
  void record({
    required String pluginId,
    required String task,
    required Duration duration,
  }) => _metrics.add(
    AIBenchmark(
      pluginId: pluginId,
      task: task,
      durationMs: duration.inMilliseconds,
      cpuCores: Platform.numberOfProcessors,
      ramBytes: ProcessInfo.currentRss,
      timestamp: DateTime.now(),
    ),
  );
}
