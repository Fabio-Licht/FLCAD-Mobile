import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../contracts/bridge_selection.dart';

class CameraPickingContext {
  const CameraPickingContext({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.inverseViewProjection,
  });
  final double viewportWidth, viewportHeight;
  final List<double> inverseViewProjection;
}

class CameraPicking {
  const CameraPicking();
  MeshRay ray({
    required double screenX,
    required double screenY,
    required CameraPickingContext camera,
  }) {
    if (camera.viewportWidth <= 0 || camera.viewportHeight <= 0) {
      throw ArgumentError('Viewport dimensions must be positive.');
    }
    if (camera.inverseViewProjection.length != 16) {
      throw ArgumentError(
        'Inverse view-projection matrix must contain 16 values.',
      );
    }
    final x = 2 * screenX / camera.viewportWidth - 1;
    final y = 1 - 2 * screenY / camera.viewportHeight;
    final near = _unproject(x, y, -1, camera.inverseViewProjection);
    final far = _unproject(x, y, 1, camera.inverseViewProjection);
    final direction = (far - near).normalized;
    if (direction.length == 0) {
      throw StateError('Camera ray has zero direction.');
    }
    return MeshRay(near, direction);
  }

  Vector3 _unproject(double x, double y, double z, List<double> m) {
    final rx = m[0] * x + m[4] * y + m[8] * z + m[12];
    final ry = m[1] * x + m[5] * y + m[9] * z + m[13];
    final rz = m[2] * x + m[6] * y + m[10] * z + m[14];
    final rw = m[3] * x + m[7] * y + m[11] * z + m[15];
    if (rw == 0) {
      throw StateError(
        'Camera unprojection produced zero homogeneous coordinate.',
      );
    }
    return Vector3(rx / rw, ry / rw, rz / rw);
  }
}
