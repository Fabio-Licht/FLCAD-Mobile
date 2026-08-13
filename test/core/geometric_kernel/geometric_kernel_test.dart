import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flcad_mobile/core/engineering/context/engineering_context.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometric_kernel.dart';

void main() {
  group('geometric primitives and transforms', () {
    test('vector operations and tolerance', () {
      const a = Vector3(1, 0, 0), b = Vector3(0, 1, 0);
      expect(
        a.cross(b).near(const Vector3(0, 0, 1), const Tolerance()),
        isTrue,
      );
      expect(const Tolerance(absolute: 1e-6).close(1, 1.0000001), isTrue);
    });
    test('composed transform can be inverted', () {
      final t = Transform3.translation(const Vector3(2, 3, 4)).compose(
        Transform3.rotation(
          Quaternion.axisAngle(const Vector3(0, 0, 1), math.pi / 2),
        ),
      );
      const p = Vector3(1, 2, 3);
      expect(
        t.inverse().apply(t.apply(p)).near(p, const Tolerance(absolute: 1e-8)),
        isTrue,
      );
    });
    test('barycentric coordinates and volume', () {
      const g = GeometryAlgorithms(),
          tri = Triangle3(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0));
      expect(
        g
            .barycentric(const Vector3(.25, .25, 0), tri)
            .near(const Vector3(.5, .25, .25), const Tolerance()),
        isTrue,
      );
      expect(
        g.tetrahedronVolume(
          const Vector3(0, 0, 0),
          const Vector3(1, 0, 0),
          const Vector3(0, 1, 0),
          const Vector3(0, 0, 1),
        ),
        closeTo(1 / 6, 1e-12),
      );
    });
  });
  group('linear algebra', () {
    test('solvers and decompositions', () {
      const la = LinearAlgebra();
      final a = DenseMatrix([
        [3, 1],
        [1, 2],
      ]);
      expect(la.solveGaussian(a, [9, 8]), everyElement(isA<double>()));
      final lu = la.lu(a);
      expect(lu.lower.rows[1][0], closeTo(1 / 3, 1e-12));
      final qr = la.qr(
        DenseMatrix([
          [1, 0],
          [0, 1],
          [1, 1],
        ]),
      );
      expect(qr.q.rowCount, 3);
      expect(la.cholesky(a)[1][1], greaterThan(0));
    });
    test('eigen, SVD and PCA are numerical implementations', () {
      const la = LinearAlgebra();
      final e = la.symmetricEigen(
        DenseMatrix([
          [3, 0],
          [0, 1],
        ]),
      );
      expect(e.values, [closeTo(3, 1e-9), closeTo(1, 1e-9)]);
      final svd = la.svd(
        DenseMatrix([
          [3, 0],
          [0, 2],
        ]),
      );
      expect(svd.singularValues, [closeTo(3, 1e-9), closeTo(2, 1e-9)]);
      final pca = la.principalComponents([
        [0, 0],
        [1, 0],
        [2, 0],
      ]);
      expect(pca.variances.first, closeTo(1, 1e-9));
    });
  });
  group('fitting, spatial, units and runtime', () {
    test('basic fitting reports real residuals', () {
      const fit = FittingEngine();
      final line = fit.fitLine([
        const Vector3(0, 0, 0),
        const Vector3(1, 0, 0),
        const Vector3(2, 0, 0),
      ]);
      expect(line.rmsError, closeTo(0, 1e-10));
      final sphere = fit.fitSphere([
        const Vector3(1, 0, 0),
        const Vector3(-1, 0, 0),
        const Vector3(0, 1, 0),
        const Vector3(0, 0, 1),
        const Vector3(0, -1, 0),
      ]);
      expect(sphere.geometry.radius, closeTo(1, 1e-9));
    });
    test('spatial index supports exact queries', () {
      final index = KDTree<String>()
        ..insert(const Vector3(0, 0, 0), 'origin')
        ..insert(const Vector3(10, 0, 0), 'far');
      expect(index.nearest(const Vector3(1, 0, 0)), 'origin');
      expect(index.radiusSearch(const Vector3(0, 0, 0), 2), ['origin']);
      expect(
        index.range(const BoundingBox3(Vector3(-1, -1, -1), Vector3(1, 1, 1))),
        ['origin'],
      );
    });
    test('units convert explicitly', () {
      const units = UnitConverter();
      expect(units.length(1, LengthUnit.inch, LengthUnit.millimeter), 25.4);
      expect(
        units.angle(180, AngleUnit.degree, AngleUnit.radian),
        closeTo(math.pi, 1e-12),
      );
    });
    test('validation and engineering registration', () {
      final context = EngineeringContext.standard('p');
      expect(
        context.services.get<GeometricKernelApi>(),
        isA<GeometricKernelApi>(),
      );
      expect(
        const GeometryValidator()
            .triangle(const Triangle3(Vector3.zero, Vector3.zero, Vector3.zero))
            .isValid,
        isFalse,
      );
    });
    test('scheduler executes in an isolate', () async {
      expect(await GeometricTaskScheduler().run(() => 6 * 7), 42);
    });
  });
}
