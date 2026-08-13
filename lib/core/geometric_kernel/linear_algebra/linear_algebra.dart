import 'dart:math' as math;

class DenseMatrix {
  DenseMatrix(List<List<double>> values)
    : rows = values.map(List<double>.from).toList() {
    if (rows.isNotEmpty && rows.any((row) => row.length != rows.first.length)) {
      throw ArgumentError('Matrix rows must have equal length');
    }
  }
  final List<List<double>> rows;
  int get rowCount => rows.length;
  int get columnCount => rows.isEmpty ? 0 : rows.first.length;
  DenseMatrix get transpose => DenseMatrix(
    List.generate(
      columnCount,
      (c) => List.generate(rowCount, (r) => rows[r][c]),
    ),
  );
}

class EigenDecomposition {
  const EigenDecomposition(this.values, this.vectors);
  final List<double> values;
  final List<List<double>> vectors;
}

class PrincipalComponents {
  const PrincipalComponents(this.mean, this.variances, this.axes);
  final List<double> mean, variances;
  final List<List<double>> axes;
}

class LUDecomposition {
  const LUDecomposition(this.lower, this.upper, this.permutation);
  final DenseMatrix lower, upper;
  final List<int> permutation;
}

class QRDecomposition {
  const QRDecomposition(this.q, this.r);
  final DenseMatrix q, r;
}

class SVDDecomposition {
  const SVDDecomposition(this.u, this.singularValues, this.v);
  final DenseMatrix u, v;
  final List<double> singularValues;
}

class LinearAlgebra {
  const LinearAlgebra();
  List<double> solveGaussian(DenseMatrix a, List<double> b) {
    final n = a.rowCount;
    if (n != a.columnCount || b.length != n) {
      throw ArgumentError('Square system required');
    }
    final m = List.generate(n, (r) => [...a.rows[r], b[r]]);
    for (var i = 0; i < n; i++) {
      var pivot = i;
      for (var r = i + 1; r < n; r++) {
        if (m[r][i].abs() > m[pivot][i].abs()) pivot = r;
      }
      if (m[pivot][i].abs() < 1e-14) throw StateError('Singular system');
      final tmp = m[i];
      m[i] = m[pivot];
      m[pivot] = tmp;
      for (var r = i + 1; r < n; r++) {
        final f = m[r][i] / m[i][i];
        for (var c = i; c <= n; c++) {
          m[r][c] -= f * m[i][c];
        }
      }
    }
    final x = List<double>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      var sum = m[i][n];
      for (var c = i + 1; c < n; c++) {
        sum -= m[i][c] * x[c];
      }
      x[i] = sum / m[i][i];
    }
    return x;
  }

  List<double> leastSquares(
    DenseMatrix a,
    List<double> b, {
    List<double>? weights,
  }) {
    if (a.rowCount != b.length ||
        weights != null && weights.length != b.length) {
      throw ArgumentError('Dimension mismatch');
    }
    final n = a.columnCount,
        ata = List.generate(n, (_) => List<double>.filled(n, 0)),
        atb = List<double>.filled(n, 0);
    for (var r = 0; r < a.rowCount; r++) {
      final w = weights == null ? 1.0 : weights[r];
      for (var i = 0; i < n; i++) {
        atb[i] += a.rows[r][i] * b[r] * w;
        for (var j = 0; j < n; j++) {
          ata[i][j] += a.rows[r][i] * a.rows[r][j] * w;
        }
      }
    }
    return solveGaussian(DenseMatrix(ata), atb);
  }

  List<List<double>> cholesky(DenseMatrix a) {
    final n = a.rowCount,
        l = List.generate(n, (_) => List<double>.filled(n, 0));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j <= i; j++) {
        var sum = a.rows[i][j];
        for (var k = 0; k < j; k++) {
          sum -= l[i][k] * l[j][k];
        }
        if (i == j) {
          if (sum <= 0) throw StateError('Matrix not positive definite');
          l[i][j] = math.sqrt(sum);
        } else {
          l[i][j] = sum / l[j][j];
        }
      }
    }
    return l;
  }

  LUDecomposition lu(DenseMatrix a) {
    if (a.rowCount != a.columnCount) {
      throw ArgumentError('Square matrix required');
    }
    final n = a.rowCount,
        u = a.rows.map(List<double>.from).toList(),
        l = List.generate(n, (_) => List<double>.filled(n, 0)),
        p = List.generate(n, (i) => i);
    for (var k = 0; k < n; k++) {
      var pivot = k;
      for (var r = k + 1; r < n; r++) {
        if (u[r][k].abs() > u[pivot][k].abs()) pivot = r;
      }
      if (u[pivot][k].abs() < 1e-14) throw StateError('Singular matrix');
      if (pivot != k) {
        final tu = u[k];
        u[k] = u[pivot];
        u[pivot] = tu;
        final tp = p[k];
        p[k] = p[pivot];
        p[pivot] = tp;
        for (var c = 0; c < k; c++) {
          final t = l[k][c];
          l[k][c] = l[pivot][c];
          l[pivot][c] = t;
        }
      }
      l[k][k] = 1;
      for (var r = k + 1; r < n; r++) {
        final f = u[r][k] / u[k][k];
        l[r][k] = f;
        for (var c = k; c < n; c++) {
          u[r][c] -= f * u[k][c];
        }
      }
    }
    return LUDecomposition(DenseMatrix(l), DenseMatrix(u), p);
  }

  QRDecomposition qr(DenseMatrix a) {
    final m = a.rowCount,
        n = a.columnCount,
        qCols = <List<double>>[],
        r = List.generate(n, (_) => List<double>.filled(n, 0));
    for (var j = 0; j < n; j++) {
      var v = List.generate(m, (i) => a.rows[i][j]);
      for (var i = 0; i < j; i++) {
        r[i][j] = _dot(qCols[i], v);
        v = List.generate(m, (k) => v[k] - r[i][j] * qCols[i][k]);
      }
      r[j][j] = math.sqrt(_dot(v, v));
      if (r[j][j] < 1e-14) throw StateError('Rank deficient matrix');
      qCols.add(v.map((x) => x / r[j][j]).toList());
    }
    return QRDecomposition(
      DenseMatrix(
        List.generate(m, (i) => List.generate(n, (j) => qCols[j][i])),
      ),
      DenseMatrix(r),
    );
  }

  EigenDecomposition symmetricEigen(
    DenseMatrix input, {
    int maxIterations = 80,
    double tolerance = 1e-12,
  }) {
    if (input.rowCount != input.columnCount) {
      throw ArgumentError('Square matrix required');
    }
    final n = input.rowCount,
        a = input.rows.map(List<double>.from).toList(),
        v = List.generate(
          n,
          (r) => List.generate(n, (c) => r == c ? 1.0 : 0.0),
        );
    for (var iteration = 0; iteration < maxIterations; iteration++) {
      var p = 0, q = n > 1 ? 1 : 0, max = 0.0;
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          if (a[i][j].abs() > max) {
            max = a[i][j].abs();
            p = i;
            q = j;
          }
        }
      }
      if (max < tolerance) break;
      final phi = 0.5 * math.atan2(2 * a[p][q], a[q][q] - a[p][p]),
          c = math.cos(phi),
          s = math.sin(phi);
      for (var i = 0; i < n; i++) {
        final aip = a[i][p], aiq = a[i][q];
        a[i][p] = c * aip - s * aiq;
        a[i][q] = s * aip + c * aiq;
      }
      for (var j = 0; j < n; j++) {
        final apj = a[p][j], aqj = a[q][j];
        a[p][j] = c * apj - s * aqj;
        a[q][j] = s * apj + c * aqj;
      }
      for (var i = 0; i < n; i++) {
        final vip = v[i][p], viq = v[i][q];
        v[i][p] = c * vip - s * viq;
        v[i][q] = s * vip + c * viq;
      }
    }
    final order = List.generate(n, (i) => i)
      ..sort((i, j) => a[j][j].compareTo(a[i][i]));
    return EigenDecomposition(
      order.map((i) => a[i][i]).toList(),
      order.map((i) => List.generate(n, (r) => v[r][i])).toList(),
    );
  }

  PrincipalComponents principalComponents(List<List<double>> samples) {
    if (samples.length < 2) {
      throw ArgumentError('At least two samples required');
    }
    final d = samples.first.length;
    if (samples.any((s) => s.length != d)) {
      throw ArgumentError('Dimension mismatch');
    }
    final mean = List.generate(
          d,
          (i) =>
              samples.map((s) => s[i]).reduce((a, b) => a + b) / samples.length,
        ),
        cov = List.generate(d, (_) => List<double>.filled(d, 0));
    for (final sample in samples) {
      for (var i = 0; i < d; i++) {
        for (var j = 0; j < d; j++) {
          cov[i][j] +=
              (sample[i] - mean[i]) *
              (sample[j] - mean[j]) /
              (samples.length - 1);
        }
      }
    }
    final eigen = symmetricEigen(DenseMatrix(cov));
    return PrincipalComponents(mean, eigen.values, eigen.vectors);
  }

  SVDDecomposition svd(DenseMatrix a) {
    final eigen = symmetricEigen(_multiply(a.transpose, a)),
        singular = eigen.values.map((v) => math.sqrt(math.max(0, v))).toList(),
        v = DenseMatrix(
          List.generate(
            a.columnCount,
            (r) => List.generate(a.columnCount, (c) => eigen.vectors[c][r]),
          ),
        ),
        uRows = List.generate(
          a.rowCount,
          (_) => List<double>.filled(a.columnCount, 0),
        );
    for (var c = 0; c < a.columnCount; c++) {
      if (singular[c] > 1e-14) {
        for (var r = 0; r < a.rowCount; r++) {
          for (var k = 0; k < a.columnCount; k++) {
            uRows[r][c] += a.rows[r][k] * v.rows[k][c] / singular[c];
          }
        }
      }
    }
    return SVDDecomposition(DenseMatrix(uRows), singular, v);
  }

  DenseMatrix _multiply(DenseMatrix a, DenseMatrix b) => DenseMatrix(
    List.generate(
      a.rowCount,
      (r) => List.generate(
        b.columnCount,
        (c) => List.generate(
          a.columnCount,
          (k) => a.rows[r][k] * b.rows[k][c],
        ).reduce((x, y) => x + y),
      ),
    ),
  );
  double _dot(List<double> a, List<double> b) =>
      List.generate(a.length, (i) => a[i] * b[i]).reduce((x, y) => x + y);
}
