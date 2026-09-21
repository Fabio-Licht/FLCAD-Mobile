import 'dart:math' as math;

import '../geometric_kernel/geometry/vectors.dart';
import '../geometric_kernel/linear_algebra/matrices.dart';
import '../geometric_kernel/transforms/transform3.dart';

/// Immutable, bounded rigid-operation stack. Original asset coordinates stay local.
final class EntityPlacement {
  EntityPlacement._(this.pivotLocal, this.operations);

  static const maxOperations = 256;
  final List<double> pivotLocal;
  final List<RigidPlacementOperation> operations;

  factory EntityPlacement.identity(List<double> pivotLocal) =>
      EntityPlacement._(_vector(pivotLocal, 'pivot'), const []);

  /// Creates a placement whose complete local-to-world frame is [matrix].
  ///
  /// The durable representation remains the established translate/rotate
  /// operation stack: a rotation about local zero followed by a world
  /// translation.  This deliberately rejects scale, reflection and shear.
  factory EntityPlacement.fromRigidMatrix(Matrix4 matrix) {
    validateRigidMatrix(matrix);
    final m = matrix.values;
    final rotation = _quaternionFromRotation(m);
    final result = EntityPlacement.identity(const [0, 0, 0])
        ._append(RigidPlacementOperation._('rotate', rotation))
        .translate(m[3], m[7], m[11]);
    // Keep this assertion close to the conversion: placement is a durable
    // contract, so a lossy matrix-to-operation conversion is unacceptable.
    final actual = result.matrix.values;
    for (var i = 0; i < 16; i++) {
      if ((actual[i] - m[i]).abs() > 1e-8) {
        throw const FormatException(
          'Rigid placement conversion lost precision',
        );
      }
    }
    return result;
  }

  EntityPlacement translate(double x, double y, double z) => _append(
    RigidPlacementOperation._('translate', _vector([x, y, z], 'translation')),
  );

  EntityPlacement rotate(double x, double y, double z, double degrees) {
    final axis = _vector([x, y, z], 'axis');
    if (!degrees.isFinite ||
        degrees.abs() > 360000 ||
        Vector3(axis[0], axis[1], axis[2]).length < 1e-12) {
      throw const FormatException('Invalid placement rotation');
    }
    final q = Quaternion.axisAngle(Vector3(x, y, z), degrees * math.pi / 180);
    return _append(
      RigidPlacementOperation._('rotate', _quaternion([q.x, q.y, q.z, q.w])),
    );
  }

  EntityPlacement _append(RigidPlacementOperation operation) {
    if (operations.length >= maxOperations) {
      throw const FormatException('Placement operation limit exceeded');
    }
    final next = EntityPlacement._(
      pivotLocal,
      List.unmodifiable([...operations, operation]),
    );
    next.matrix; // Validate cumulative bounds and rigidity before publication.
    return next;
  }

  Matrix4 get matrix {
    var result = Matrix4.identity();
    for (final operation in operations) {
      final v = operation.values;
      if (operation.kind == 'translate') {
        result =
            Transform3.translation(Vector3(v[0], v[1], v[2])).matrix * result;
      } else {
        final pivot = result.transformPoint(
          Vector3(pivotLocal[0], pivotLocal[1], pivotLocal[2]),
        );
        final rotation = Transform3.rotation(
          Quaternion(v[0], v[1], v[2], v[3]),
        );
        result =
            Transform3.translation(
              pivot,
            ).compose(rotation).compose(Transform3.translation(-pivot)).matrix *
            result;
      }
    }
    validateRigidMatrix(result);
    return result;
  }

  /// Also rejects singular matrices; scale, reflection and perspective are unsupported.
  static void validateRigidMatrix(Matrix4 matrix) {
    final m = matrix.values;
    if (m.length != 16 ||
        m.any((v) => !v.isFinite || v.abs() > 1e9) ||
        m[12] != 0 ||
        m[13] != 0 ||
        m[14] != 0 ||
        m[15] != 1) {
      throw const FormatException('Invalid rigid placement matrix');
    }
    final a = Vector3(m[0], m[4], m[8]);
    final b = Vector3(m[1], m[5], m[9]);
    final c = Vector3(m[2], m[6], m[10]);
    if ((a.length - 1).abs() > 1e-8 ||
        (b.length - 1).abs() > 1e-8 ||
        (c.length - 1).abs() > 1e-8 ||
        a.dot(b).abs() > 1e-8 ||
        a.dot(c).abs() > 1e-8 ||
        b.dot(c).abs() > 1e-8 ||
        (a.dot(b.cross(c)) - 1).abs() > 1e-8) {
      throw const FormatException(
        'Placement matrix must be rigid and nonsingular',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'schema': 'flcad.entity-placement',
    'version': 1,
    'frameUnit': 'mm',
    'space': 'world',
    'pivotLocal': pivotLocal,
    'operations': operations.map((o) => o.toJson()).toList(),
  };

  factory EntityPlacement.fromJson(Map<String, dynamic> json) {
    if (!_keys(json, {
          'schema',
          'version',
          'frameUnit',
          'space',
          'pivotLocal',
          'operations',
        }) ||
        json['schema'] != 'flcad.entity-placement' ||
        json['version'] is! int ||
        json['version'] != 1 ||
        json['frameUnit'] != 'mm' ||
        json['space'] != 'world' ||
        json['operations'] is! List ||
        (json['operations'] as List).length > maxOperations) {
      throw const FormatException('Invalid entity placement schema');
    }
    final result = EntityPlacement._(
      _vector(json['pivotLocal'], 'pivot'),
      List.unmodifiable(
        (json['operations'] as List).map((raw) {
          if (raw is! Map || !_keys(raw, {'kind', 'values'})) {
            throw const FormatException('Invalid placement operation');
          }
          return switch (raw['kind']) {
            'translate' => RigidPlacementOperation._(
              'translate',
              _vector(raw['values'], 'translation'),
            ),
            'rotate' => RigidPlacementOperation._(
              'rotate',
              _quaternion(raw['values']),
            ),
            _ => throw const FormatException('Unsupported placement operation'),
          };
        }),
      ),
    );
    result.matrix;
    return result;
  }

  static bool _keys(Map value, Set<String> expected) =>
      value.length == expected.length && value.keys.every(expected.contains);

  static List<double> _vector(Object? raw, String field) {
    if (raw is! List ||
        raw.length != 3 ||
        raw.any((v) => v is! num || !v.isFinite || v.abs() > 1e9)) {
      throw FormatException('Invalid placement $field');
    }
    return List.unmodifiable(raw.map((v) => (v as num).toDouble()));
  }

  static List<double> _quaternion(Object? raw) {
    if (raw is! List ||
        raw.length != 4 ||
        raw.any((v) => v is! num || !v.isFinite)) {
      throw const FormatException('Invalid placement quaternion');
    }
    final values = raw.map((v) => (v as num).toDouble()).toList();
    final norm = values.fold<double>(0, (sum, v) => sum + v * v);
    if (!norm.isFinite || (norm - 1).abs() > 1e-10) {
      throw const FormatException('Placement quaternion must be normalized');
    }
    return List.unmodifiable(values);
  }

  static List<double> _quaternionFromRotation(List<double> m) {
    // Numerically stable conversion for every proper rotation, including
    // rotations near 180 degrees (where the trace-only formula is unstable).
    final trace = m[0] + m[5] + m[10];
    late double x, y, z, w;
    if (trace > 0) {
      final s = math.sqrt(trace + 1) * 2;
      w = .25 * s;
      x = (m[9] - m[6]) / s;
      y = (m[2] - m[8]) / s;
      z = (m[4] - m[1]) / s;
    } else if (m[0] > m[5] && m[0] > m[10]) {
      final s = math.sqrt(1 + m[0] - m[5] - m[10]) * 2;
      w = (m[9] - m[6]) / s;
      x = .25 * s;
      y = (m[1] + m[4]) / s;
      z = (m[2] + m[8]) / s;
    } else if (m[5] > m[10]) {
      final s = math.sqrt(1 + m[5] - m[0] - m[10]) * 2;
      w = (m[2] - m[8]) / s;
      x = (m[1] + m[4]) / s;
      y = .25 * s;
      z = (m[6] + m[9]) / s;
    } else {
      final s = math.sqrt(1 + m[10] - m[0] - m[5]) * 2;
      w = (m[4] - m[1]) / s;
      x = (m[2] + m[8]) / s;
      y = (m[6] + m[9]) / s;
      z = .25 * s;
    }
    final length = math.sqrt(x * x + y * y + z * z + w * w);
    if (!length.isFinite || length <= 1e-12) {
      throw const FormatException('Invalid rigid placement rotation');
    }
    return List.unmodifiable([x / length, y / length, z / length, w / length]);
  }
}

final class RigidPlacementOperation {
  const RigidPlacementOperation._(this.kind, this.values);
  final String kind;
  final List<double> values;
  Map<String, dynamic> toJson() => {'kind': kind, 'values': values};
}
