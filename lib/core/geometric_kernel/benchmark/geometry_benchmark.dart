class GeometryBenchmarkResult {
  const GeometryBenchmarkResult(this.name, this.iterations, this.elapsed);
  final String name;
  final int iterations;
  final Duration elapsed;
  double get operationsPerSecond =>
      iterations / (elapsed.inMicroseconds / 1000000);
}

class GeometryBenchmark {
  const GeometryBenchmark();
  GeometryBenchmarkResult run(
    String name,
    int iterations,
    void Function() operation,
  ) {
    final watch = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      operation();
    }
    watch.stop();
    return GeometryBenchmarkResult(name, iterations, watch.elapsed);
  }
}
