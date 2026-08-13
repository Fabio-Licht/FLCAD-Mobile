import '../../smart_regions/models/geometry.dart';
import '../brain/reverse_brain.dart';

class IntelligenceBenchmarkResult {
  const IntelligenceBenchmarkResult(
    this.elapsed,
    this.triangles,
    this.confidence,
  );
  final Duration elapsed;
  final int triangles;
  final double confidence;
  double get trianglesPerSecond =>
      triangles / (elapsed.inMicroseconds / 1000000);
}

class IntelligenceBenchmark {
  const IntelligenceBenchmark();
  IntelligenceBenchmarkResult run(String projectId, MeshTopology mesh) {
    final watch = Stopwatch()..start(),
        result = const ReverseBrain().reason(projectId, mesh);
    watch.stop();
    return IntelligenceBenchmarkResult(
      watch.elapsed,
      mesh.triangles.length,
      result.twin.decision.confidence,
    );
  }
}
