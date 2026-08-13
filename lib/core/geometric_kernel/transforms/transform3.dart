import '../geometry/vectors.dart';
import '../linear_algebra/matrices.dart';
import 'dart:math' as math;

class TransformComponents {
  const TransformComponents(this.translation, this.rotation, this.scale);
  final Vector3 translation, scale;
  final Quaternion rotation;
}

class Transform3 {
  const Transform3(this.matrix);
  final Matrix4 matrix;
  factory Transform3.identity() => Transform3(Matrix4.identity());
  factory Transform3.translation(Vector3 v) => Transform3(
    Matrix4([1, 0, 0, v.x, 0, 1, 0, v.y, 0, 0, 1, v.z, 0, 0, 0, 1]),
  );
  factory Transform3.scale(Vector3 v) => Transform3(
    Matrix4([v.x, 0, 0, 0, 0, v.y, 0, 0, 0, 0, v.z, 0, 0, 0, 0, 1]),
  );
  factory Transform3.rotation(Quaternion q) {
    final m = q.toMatrix3().values;
    return Transform3(
      Matrix4([
        m[0],
        m[1],
        m[2],
        0,
        m[3],
        m[4],
        m[5],
        0,
        m[6],
        m[7],
        m[8],
        0,
        0,
        0,
        0,
        1,
      ]),
    );
  }
  factory Transform3.align(Vector3 from, Vector3 to) {
    final a = from.normalized, b = to.normalized;
    if (a.length == 0 || b.length == 0) {
      throw ArgumentError('Alignment vectors must be non-zero');
    }
    final dot = a.dot(b).clamp(-1, 1).toDouble();
    if (dot > 1 - 1e-12) return Transform3.identity();
    if (dot < -1 + 1e-12) {
      final helper = a.x.abs() < .9
          ? const Vector3(1, 0, 0)
          : const Vector3(0, 1, 0);
      return Transform3.rotation(
        Quaternion.axisAngle(a.cross(helper), math.pi),
      );
    }
    return Transform3.rotation(
      Quaternion.axisAngle(a.cross(b), math.acos(dot)),
    );
  }
  Transform3 compose(Transform3 other) => Transform3(matrix * other.matrix);
  Transform3 inverse() => Transform3(matrix.inverse());
  Vector3 apply(Vector3 p) => matrix.transformPoint(p);
  factory Transform3.mirror(Vector3 normal) {
    final n = normal.normalized, x = n.x, y = n.y, z = n.z;
    return Transform3(
      Matrix4([
        1 - 2 * x * x,
        -2 * x * y,
        -2 * x * z,
        0,
        -2 * y * x,
        1 - 2 * y * y,
        -2 * y * z,
        0,
        -2 * z * x,
        -2 * z * y,
        1 - 2 * z * z,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
  }
  TransformComponents decompose() {
    final m = matrix.values,
        translation = Vector3(m[3], m[7], m[11]),
        scale = Vector3(
          Vector3(m[0], m[4], m[8]).length,
          Vector3(m[1], m[5], m[9]).length,
          Vector3(m[2], m[6], m[10]).length,
        );
    if (scale.x == 0 || scale.y == 0 || scale.z == 0) {
      throw StateError('Singular transform');
    }
    final r00 = m[0] / scale.x,
        r11 = m[5] / scale.y,
        r22 = m[10] / scale.z,
        trace = r00 + r11 + r22;
    Quaternion rotation;
    if (trace > 0) {
      final s = math.sqrt(trace + 1) * 2;
      rotation = Quaternion(
        (m[9] / scale.y - m[6] / scale.z) / s,
        (m[2] / scale.z - m[8] / scale.x) / s,
        (m[4] / scale.x - m[1] / scale.y) / s,
        s / 4,
      );
    } else {
      rotation = const Quaternion(0, 0, 0, 1);
    }
    return TransformComponents(translation, rotation.normalized, scale);
  }
}
