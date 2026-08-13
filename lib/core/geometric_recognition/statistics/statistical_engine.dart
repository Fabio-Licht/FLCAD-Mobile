import 'dart:math' as math;

import '../../geometric_kernel/linear_algebra/linear_algebra.dart';
import '../models/recognition_models.dart';

class ResidualAnalysis {
  const ResidualAnalysis(
    this.values,
    this.rms,
    this.maximum,
    this.mean,
    this.inlierRatio,
    this.confidenceInterval,
  );
  final List<double> values;
  final double rms, maximum, mean, inlierRatio;
  final (double, double) confidenceInterval;
}

class RecognitionStatisticalEngine {
  const RecognitionStatisticalEngine();
  PrincipalComponents pca(RecognitionObservation observation) =>
      const LinearAlgebra().principalComponents(
        observation.points.map((p) => [p.x, p.y, p.z]).toList(),
      );
  List<double> leastSquares(DenseMatrix a, List<double> b) =>
      const LinearAlgebra().leastSquares(a, b);
  List<double> robustWeights(List<double> residuals) {
    if (residuals.isEmpty) return const [];
    final sorted = residuals.map((e) => e.abs()).toList()..sort();
    final scale = sorted[sorted.length ~/ 2];
    if (scale == 0) return List.filled(residuals.length, 1);
    return residuals.map((r) => 1 / (1 + math.pow(r / scale, 2))).toList();
  }

  ResidualAnalysis residuals(List<double> values) {
    if (values.isEmpty) throw ArgumentError('Residuals cannot be empty');
    final absolute = values.map((e) => e.abs()).toList(),
        mean = absolute.reduce((a, b) => a + b) / absolute.length,
        rms = math.sqrt(
          absolute.map((e) => e * e).reduce((a, b) => a + b) / absolute.length,
        ),
        maximum = absolute.reduce(math.max),
        sorted = [...absolute]..sort(),
        median = sorted[sorted.length ~/ 2],
        scale = median == 0 ? rms : median,
        inliers = absolute.where((e) => e <= scale * 2.5).length,
        standardError = rms / math.sqrt(absolute.length);
    return ResidualAnalysis(
      List.unmodifiable(absolute),
      rms,
      maximum,
      mean,
      inliers / absolute.length,
      (math.max(0, mean - 1.96 * standardError), mean + 1.96 * standardError),
    );
  }
}
