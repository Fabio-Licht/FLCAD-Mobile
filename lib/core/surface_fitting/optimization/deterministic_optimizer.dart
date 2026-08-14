import 'dart:math' as math;

import '../models/surface_fitting_models.dart';

class DeterministicSurfaceOptimizer {
  const DeterministicSurfaceOptimizer();
  List<int> ransacSample(int count, int required) {
    if (count <= required) {
      return List.generate(count, (i) => i);
    }
    final step = (count - 1) / (required - 1);
    return List.generate(required, (i) => (i * step).round());
  }

  List<double> robustWeights(List<double> residuals) {
    if (residuals.isEmpty) return const [];
    final sorted = residuals.map((e) => e.abs()).toList()..sort();
    final median = sorted[sorted.length ~/ 2],
        limit = math.max(median * 1.5, 1e-12);
    return residuals
        .map((r) => r.abs() <= limit ? 1.0 : limit / r.abs())
        .toList();
  }

  double weightedMean(List<double> values, List<double> weights) {
    var sum = 0.0, total = 0.0;
    for (var i = 0; i < values.length; i++) {
      sum += values[i] * weights[i];
      total += weights[i];
    }
    return total == 0 ? 0 : sum / total;
  }

  ResidualStatistics analyze(List<double> residuals) {
    if (residuals.isEmpty) {
      return const ResidualStatistics(
        values: [],
        rms: double.infinity,
        maximum: double.infinity,
        mean: double.infinity,
        standardDeviation: double.infinity,
        distribution: {},
      );
    }
    final absolute = residuals.map((e) => e.abs()).toList();
    final mean = absolute.reduce((a, b) => a + b) / absolute.length;
    final rms = math.sqrt(
      absolute.fold<double>(0, (s, e) => s + e * e) / absolute.length,
    );
    final deviation = math.sqrt(
      absolute.fold<double>(0, (s, e) => s + math.pow(e - mean, 2)) /
          absolute.length,
    );
    final maximum = absolute.reduce(math.max), scale = math.max(rms, 1e-12);
    return ResidualStatistics(
      values: List.unmodifiable(residuals),
      rms: rms,
      maximum: maximum,
      mean: mean,
      standardDeviation: deviation,
      distribution: {
        '0-1 RMS': absolute.where((e) => e <= scale).length,
        '1-2 RMS': absolute.where((e) => e > scale && e <= 2 * scale).length,
        '>2 RMS': absolute.where((e) => e > 2 * scale).length,
      },
    );
  }
}
