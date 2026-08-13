import '../models/kernel_models.dart';

class KernelAnalytics {
  final List<KernelMetric> _metrics = [];
  void record(KernelMetric metric) => _metrics.add(metric);
  List<KernelMetric> get metrics => List.unmodifiable(_metrics);
  int get operations => _metrics.length;
  int get entities => _metrics.fold(0, (a, b) => a + b.entityCount);
  Duration get elapsed => _metrics.fold(Duration.zero, (a, b) => a + b.elapsed);
  int get memoryDeltaBytes =>
      _metrics.fold(0, (a, b) => a + b.memoryDeltaBytes);
}
