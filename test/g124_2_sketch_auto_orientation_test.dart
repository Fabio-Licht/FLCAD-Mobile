import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('G-124.2 Sketch Auto Orientation', () {
    test(
      'XY enters instantly from positive normal with local axes upright',
      () {
        final camera = CadCameraController();
        camera.enterSketch(
          origin: Vector3.zero,
          normal: Vector3(0, 0, 1),
          xDirection: Vector3(1, 0, 0),
          visualSize: 60,
        );
        expect(camera.projectionMode, CadProjectionMode.orthographic);
        expect(camera.eye.x, closeTo(0, 1e-12));
        expect(camera.eye.y, closeTo(0, 1e-12));
        expect(camera.eye.z, greaterThan(0));
        expect(camera.up.distanceTo(Vector3(0, 1, 0)), lessThan(1e-12));
        expect(camera.target.distanceTo(Vector3.zero), lessThan(1e-12));
        expect(camera.viewScale, closeTo(66, 1e-12));
      },
    );

    test('YZ preserves support normal and shows local +Y upward', () {
      final camera = CadCameraController();
      camera.enterSketch(
        origin: Vector3(4, 5, 6),
        normal: Vector3(1, 0, 0),
        xDirection: Vector3(0, 1, 0),
      );
      expect(
        (camera.eye - camera.target).normalized.distanceTo(Vector3(1, 0, 0)),
        lessThan(1e-12),
      );
      expect(camera.up.distanceTo(Vector3(0, 0, 1)), lessThan(1e-12));
    });

    test('ZX never inherits an opposite side from the previous camera', () {
      final camera = CadCameraController()
        ..eye = Vector3(0, -100, 0)
        ..target = Vector3.zero;
      camera.enterSketch(
        origin: Vector3.zero,
        normal: Vector3(0, 1, 0),
        xDirection: Vector3(1, 0, 0),
      );
      expect(
        (camera.eye - camera.target).normalized.distanceTo(Vector3(0, 1, 0)),
        lessThan(1e-12),
      );
      expect(camera.up.distanceTo(Vector3(0, 0, -1)), lessThan(1e-12));
    });

    test('exit restores the exact pre-Sketch camera snapshot', () {
      final camera = CadCameraController();
      final before = camera.snapshot();
      camera.enterSketch(
        origin: Vector3(10, 20, 30),
        normal: Vector3(0, 0, 1),
        xDirection: Vector3(1, 0, 0),
      );
      camera.exitSketch();
      expect(camera.eye.distanceTo(before.eye), lessThan(1e-12));
      expect(camera.target.distanceTo(before.target), lessThan(1e-12));
      expect(camera.up.distanceTo(before.up), lessThan(1e-12));
      expect(camera.projectionMode, before.projectionMode);
    });
  });
}
