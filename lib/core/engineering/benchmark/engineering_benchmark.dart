import 'dart:async';
import '../metrics/engineering_metrics.dart';

class EngineeringBenchmarkResult {
  const EngineeringBenchmarkResult(
    this.name,
    this.elapsed,
    this.success, {
    this.error,
  });
  final String name;
  final Duration elapsed;
  final bool success;
  final Object? error;
}

class EngineeringBenchmark {
  EngineeringBenchmark(this.metrics);
  final EngineeringMetrics metrics;
  Future<EngineeringBenchmarkResult> run(
    String name,
    FutureOr<void> Function() operation,
  ) async {
    final watch = Stopwatch()..start();
    try {
      await operation();
      watch.stop();
      metrics.record(
        'benchmark.elapsed',
        watch.elapsedMicroseconds,
        unit: 'us',
        tags: {'name': name},
      );
      return EngineeringBenchmarkResult(name, watch.elapsed, true);
    } catch (error) {
      watch.stop();
      return EngineeringBenchmarkResult(
        name,
        watch.elapsed,
        false,
        error: error,
      );
    }
  }
}
