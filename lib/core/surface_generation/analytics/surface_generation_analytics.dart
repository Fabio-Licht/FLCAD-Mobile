import '../../adaptive_surface/models/surface_geometry.dart';
import '../models/surface_generation_models.dart';

class SurfaceGenerationAnalytics {
  final List<SurfaceGenerationMetric> metrics = [];
  void record(SurfaceGenerationMetric metric) => metrics.add(metric);
  int get successes => metrics.where((e) => e.success).length;
  int get failures => metrics.length - successes;
  double get successRate => metrics.isEmpty ? 0 : successes / metrics.length;
  double get pieceCoverage => metrics.isEmpty
      ? 0
      : metrics.map((e) => e.coverage).fold<double>(0, (a, b) => a + b) /
            metrics.length;
  Map<SurfaceKind, int> get byType => {
    for (final kind in SurfaceKind.values)
      if (metrics.any((e) => e.kind == kind))
        kind: metrics.where((e) => e.kind == kind).length,
  };
}
