import 'dart:math' as math;
import '../geometry/vectors.dart';

class Matrix2 {
  const Matrix2(this.values);
  final List<double> values;
  double get determinant => values[0] * values[3] - values[1] * values[2];
}

class Matrix3 {
  const Matrix3(this.values);
  final List<double> values;
  factory Matrix3.identity() => const Matrix3([1, 0, 0, 0, 1, 0, 0, 0, 1]);
  Vector3 transform(Vector3 v) => Vector3(
    values[0] * v.x + values[1] * v.y + values[2] * v.z,
    values[3] * v.x + values[4] * v.y + values[5] * v.z,
    values[6] * v.x + values[7] * v.y + values[8] * v.z,
  );
  double get determinant =>
      values[0] * (values[4] * values[8] - values[5] * values[7]) -
      values[1] * (values[3] * values[8] - values[5] * values[6]) +
      values[2] * (values[3] * values[7] - values[4] * values[6]);
}

class Matrix4 {
  const Matrix4(this.values);
  final List<double> values;
  factory Matrix4.identity() =>
      const Matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
  Matrix4 operator *(Matrix4 o) {
    final r = List<double>.filled(16, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        for (var k = 0; k < 4; k++) {
          r[row * 4 + col] += values[row * 4 + k] * o.values[k * 4 + col];
        }
      }
    }
    return Matrix4(r);
  }

  Vector3 transformPoint(Vector3 p) {
    final x = values[0] * p.x + values[1] * p.y + values[2] * p.z + values[3],
        y = values[4] * p.x + values[5] * p.y + values[6] * p.z + values[7],
        z = values[8] * p.x + values[9] * p.y + values[10] * p.z + values[11],
        w = values[12] * p.x + values[13] * p.y + values[14] * p.z + values[15];
    return Vector3(x / w, y / w, z / w);
  }

  Matrix4 inverse() {
    final a = List.generate(
      4,
      (r) => [
        ...values.sublist(r * 4, r * 4 + 4),
        ...List.generate(4, (c) => r == c ? 1.0 : 0.0),
      ],
    );
    for (var i = 0; i < 4; i++) {
      var pivot = i;
      for (var r = i + 1; r < 4; r++) {
        if (a[r][i].abs() > a[pivot][i].abs()) pivot = r;
      }
      if (a[pivot][i].abs() < 1e-15) throw StateError('Singular matrix');
      final temp = a[i];
      a[i] = a[pivot];
      a[pivot] = temp;
      final d = a[i][i];
      for (var c = 0; c < 8; c++) {
        a[i][c] /= d;
      }
      for (var r = 0; r < 4; r++) {
        if (r == i) continue;
        final f = a[r][i];
        for (var c = 0; c < 8; c++) {
          a[r][c] -= f * a[i][c];
        }
      }
    }
    return Matrix4([for (final row in a) ...row.sublist(4)]);
  }
}

class Quaternion {
  const Quaternion(this.x, this.y, this.z, this.w);
  final double x, y, z, w;
  factory Quaternion.axisAngle(Vector3 axis, double angle) {
    final h = angle / 2, s = math.sin(h), a = axis.normalized;
    return Quaternion(a.x * s, a.y * s, a.z * s, math.cos(h));
  }
  Quaternion get normalized {
    final l = math.sqrt(x * x + y * y + z * z + w * w);
    return Quaternion(x / l, y / l, z / l, w / l);
  }

  Matrix3 toMatrix3() {
    final q = normalized,
        xx = q.x * q.x,
        yy = q.y * q.y,
        zz = q.z * q.z,
        xy = q.x * q.y,
        xz = q.x * q.z,
        yz = q.y * q.z,
        wx = q.w * q.x,
        wy = q.w * q.y,
        wz = q.w * q.z;
    return Matrix3([
      1 - 2 * (yy + zz),
      2 * (xy - wz),
      2 * (xz + wy),
      2 * (xy + wz),
      1 - 2 * (xx + zz),
      2 * (yz - wx),
      2 * (xz - wy),
      2 * (yz + wx),
      1 - 2 * (xx + yy),
    ]);
  }
}
