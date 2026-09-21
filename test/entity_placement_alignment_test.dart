import 'package:flcad_mobile/core/cad_document/entity_placement.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_kernel/linear_algebra/matrices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('G105A2 rigid placement frame', () {
    test('maps local origin and axes to the destination WCS without scale', () {
      // Destination X=world Y, Y=world -X, Z=world Z, origin=(25,-40,12.5).
      final placement = EntityPlacement.fromRigidMatrix(
        const Matrix4([0, -1, 0, 25, 1, 0, 0, -40, 0, 0, 1, 12.5, 0, 0, 0, 1]),
      );
      final matrix = placement.matrix;
      expect(matrix.transformPoint(Vector3.zero).toJson(), [25, -40, 12.5]);
      final origin = matrix.transformPoint(Vector3.zero);
      expect(
        (matrix.transformPoint(const Vector3(1, 0, 0)) - origin).toJson(),
        [0, 1, 0],
      );
      expect(
        (matrix.transformPoint(const Vector3(0, 1, 0)) - origin).toJson(),
        [-1, 0, 0],
      );
      EntityPlacement.validateRigidMatrix(matrix);
    });

    test('rejects scale before it can become a durable placement', () {
      expect(
        () => EntityPlacement.fromRigidMatrix(
          const Matrix4([2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
        ),
        throwsFormatException,
      );
    });
  });
}
