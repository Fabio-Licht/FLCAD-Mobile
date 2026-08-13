import '../computational_geometry/geometry_algorithms.dart';
import '../geometry/primitives.dart';
import '../geometry/vectors.dart';
import '../linear_algebra/linear_algebra.dart';
import '../numerical/numerical_methods.dart';

class FitResult<T> {
  const FitResult(
    this.geometry,
    this.rmsError,
    this.maxError,
    this.pointCount,
    this.converged,
  );
  final T geometry;
  final double rmsError, maxError;
  final int pointCount;
  final bool converged;
}

class Sphere3 {
  const Sphere3(this.center, this.radius);
  final Vector3 center;
  final double radius;
}

class Circle3 {
  const Circle3(this.center, this.normal, this.radius);
  final Vector3 center, normal;
  final double radius;
}

class FittingEngine {
  const FittingEngine();
  FitResult<Plane3> fitPlane(List<Vector3> p) {
    if (p.length < 3) throw ArgumentError('At least three points required');
    final pca = const LinearAlgebra().principalComponents(
      p.map((v) => [v.x, v.y, v.z]).toList(),
    );
    final center = const GeometryAlgorithms().centroid(p);
    final normal = Vector3(
      pca.axes[2][0],
      pca.axes[2][1],
      pca.axes[2][2],
    ).normalized;
    final plane = Plane3(center, normal);
    final errors = p.map((v) => plane.signedDistance(v).abs()).toList();
    return FitResult(
      plane,
      const ErrorMetrics().rms(errors),
      const ErrorMetrics().maximum(errors),
      p.length,
      true,
    );
  }

  FitResult<Line3> fitLine(List<Vector3> p) {
    if (p.length < 2) throw ArgumentError('At least two points required');
    final pca = const LinearAlgebra().principalComponents(
      p.map((v) => [v.x, v.y, v.z]).toList(),
    );
    final center = const GeometryAlgorithms().centroid(p);
    final direction = Vector3(pca.axes[0][0], pca.axes[0][1], pca.axes[0][2]);
    final line = Line3(center, direction);
    final errors = p
        .map((v) => const GeometryAlgorithms().pointLineDistance(v, line))
        .toList();
    return FitResult(
      line,
      const ErrorMetrics().rms(errors),
      const ErrorMetrics().maximum(errors),
      p.length,
      true,
    );
  }

  FitResult<Circle3> fitCircleXY(List<Vector3> p) {
    if (p.length < 3) throw ArgumentError('At least three points required');
    final a = DenseMatrix(p.map((v) => [2 * v.x, 2 * v.y, 1.0]).toList());
    final b = p.map((v) => v.x * v.x + v.y * v.y).toList();
    final x = const LinearAlgebra().leastSquares(a, b);
    final center = Vector3(
      x[0],
      x[1],
      p.map((v) => v.z).reduce((a, b) => a + b) / p.length,
    );
    final radius = center.distanceTo(Vector3(p.first.x, p.first.y, center.z));
    final errors = p
        .map(
          (v) =>
              (center.distanceTo(Vector3(v.x, v.y, center.z)) - radius).abs(),
        )
        .toList();
    return FitResult(
      Circle3(center, const Vector3(0, 0, 1), radius),
      const ErrorMetrics().rms(errors),
      const ErrorMetrics().maximum(errors),
      p.length,
      true,
    );
  }

  FitResult<Sphere3> fitSphere(List<Vector3> p) {
    if (p.length < 4) throw ArgumentError('At least four points required');
    final a = DenseMatrix(
      p.map((v) => [2 * v.x, 2 * v.y, 2 * v.z, 1.0]).toList(),
    );
    final b = p.map((v) => v.lengthSquared).toList();
    final x = const LinearAlgebra().leastSquares(a, b);
    final center = Vector3(x[0], x[1], x[2]);
    final radii = p.map(center.distanceTo).toList();
    final radius = radii.reduce((a, b) => a + b) / radii.length;
    final errors = radii.map((r) => (r - radius).abs()).toList();
    return FitResult(
      Sphere3(center, radius),
      const ErrorMetrics().rms(errors),
      const ErrorMetrics().maximum(errors),
      p.length,
      true,
    );
  }
}

abstract interface class CylinderFitter {
  Future<FitResult<Object>> fitCylinder(List<Vector3> points);
}

abstract interface class ConeFitter {
  Future<FitResult<Object>> fitCone(List<Vector3> points);
}

abstract interface class SurfaceFitter {
  Future<FitResult<Object>> fitSurface(List<Vector3> points);
}
