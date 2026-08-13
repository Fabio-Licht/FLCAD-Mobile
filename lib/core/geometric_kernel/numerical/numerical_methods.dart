import 'dart:math' as math;

class ConvergenceCriteria {
  const ConvergenceCriteria({
    this.tolerance = 1e-8,
    this.maxIterations = 100,
    this.gradientTolerance = 1e-8,
  });
  final double tolerance, gradientTolerance;
  final int maxIterations;
}

class NumericalResult<T> {
  const NumericalResult(
    this.value,
    this.iterations,
    this.converged,
    this.error,
  );
  final T value;
  final int iterations;
  final bool converged;
  final double error;
}

class NumericalMethods {
  const NumericalMethods();
  NumericalResult<double> newton(
    double initial,
    double Function(double) f,
    double Function(double) derivative, {
    ConvergenceCriteria criteria = const ConvergenceCriteria(),
  }) {
    var x = initial;
    for (var i = 0; i < criteria.maxIterations; i++) {
      final y = f(x), d = derivative(x);
      if (d.abs() < criteria.gradientTolerance) {
        return NumericalResult(x, i, false, y.abs());
      }
      final next = x - y / d;
      if ((next - x).abs() < criteria.tolerance) {
        return NumericalResult(next, i + 1, true, f(next).abs());
      }
      x = next;
    }
    return NumericalResult(x, criteria.maxIterations, false, f(x).abs());
  }

  NumericalResult<List<double>> gradientDescent(
    List<double> initial,
    double Function(List<double>) objective,
    List<double> Function(List<double>) gradient, {
    double rate = .01,
    ConvergenceCriteria criteria = const ConvergenceCriteria(),
  }) {
    var x = List<double>.from(initial);
    for (var i = 0; i < criteria.maxIterations; i++) {
      final g = gradient(x),
          norm = math.sqrt(g.fold<double>(0, (a, b) => a + b * b));
      if (norm < criteria.gradientTolerance) {
        return NumericalResult(x, i, true, objective(x));
      }
      x = List.generate(x.length, (j) => x[j] - rate * g[j]);
    }
    return NumericalResult(x, criteria.maxIterations, false, objective(x));
  }
}

abstract interface class NonlinearLeastSquares {
  NumericalResult<List<double>> gaussNewton(List<double> initial);
  NumericalResult<List<double>> levenbergMarquardt(List<double> initial);
}

abstract interface class RansacModel<T> {
  T fit(List<Object> samples);
  double error(T model, Object sample);
}

abstract interface class ICPFoundation {
  Future<Object> align(Object source, Object target);
}

class ErrorMetrics {
  const ErrorMetrics();
  double mean(List<double> r) => r.reduce((a, b) => a + b) / r.length;
  double rms(List<double> r) =>
      math.sqrt(r.fold<double>(0, (a, b) => a + b * b) / r.length);
  double maximum(List<double> r) => r.map((e) => e.abs()).reduce(math.max);
}
