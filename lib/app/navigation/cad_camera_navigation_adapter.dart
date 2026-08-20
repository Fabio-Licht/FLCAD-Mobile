import '../cad_viewport/camera/cad_camera_controller.dart';
import '../cad_viewport/camera/camera_pan_audit.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';
import 'navigation_contracts.dart';

/// The only bridge allowed to translate operational navigation commands into
/// mathematical camera operations.
class CadCameraNavigationAdapter implements NavigationCameraContract {
  CadCameraNavigationAdapter(this.camera);

  final CadCameraController camera;
  Vector3? _panPlaneOrigin;
  Vector3? _panPlaneNormal;

  @override
  CadCameraState get snapshot => camera.snapshot();

  @override
  void execute(NavigationCommand command) {
    switch (command) {
      case OrbitCommand():
        camera.orbit(command.yaw, command.pitch);
      case PanCommand():
        switch (command.phase) {
          case NavigationCommandPhase.begin:
            CameraPanAudit.begin();
            final view = camera.target - camera.eye;
            if (view.length > 1e-12) {
              _panPlaneOrigin = camera.target;
              _panPlaneNormal = view.normalized;
            }
          case NavigationCommandPhase.update:
            _panOnFixedFocalPlane(command);
          case NavigationCommandPhase.end:
            _panPlaneOrigin = null;
            _panPlaneNormal = null;
            CameraPanAudit.end();
        }
      case ManipulateOperationalSceneCommand():
        switch (command.phase) {
          case NavigationCommandPhase.begin:
            final view = camera.presentationTarget - camera.presentationEye;
            if (view.length > 1e-12) {
              _panPlaneOrigin = camera.presentationTarget;
              _panPlaneNormal = view.normalized;
            }
          case NavigationCommandPhase.update:
            _manipulateScene(command);
          case NavigationCommandPhase.end:
            _panPlaneOrigin = null;
            _panPlaneNormal = null;
        }
      case ZoomCommand():
        camera.zoom(command.factor, anchor: command.anchor);
      case FitCommand():
        camera.fit(command.minimum, command.maximum);
      case SetRotationCenterCommand():
        camera.setRotationCenter(command.point);
      case FocusCommand():
        camera.focusOn(command.point);
    }
  }

  void _manipulateScene(ManipulateOperationalSceneCommand command) {
    final origin = _panPlaneOrigin;
    final normal = _panPlaneNormal;
    if (origin == null || normal == null) return;
    final current = _pointOnPlane(
      command.currentX,
      command.currentY,
      origin,
      normal,
    );
    final previous = _pointOnPlane(
      command.previousX,
      command.previousY,
      origin,
      normal,
    );
    if (current == null || previous == null) return;
    camera.translateOperationalScene(current - previous);
  }

  void _panOnFixedFocalPlane(PanCommand command) {
    final origin = _panPlaneOrigin;
    final normal = _panPlaneNormal;
    if (origin == null || normal == null) return;
    final current = _pointOnPlane(
      command.currentX,
      command.currentY,
      origin,
      normal,
    );
    final previous = _pointOnPlane(
      command.previousX,
      command.previousY,
      origin,
      normal,
    );
    if (current == null || previous == null) return;

    // FreeCAD NavigationStyle::panCamera moves the camera by the negative
    // difference between current and previous projected plane points.
    final translation = previous - current;
    camera.translateCameraPosition(translation);
  }

  Vector3? _pointOnPlane(
    double screenX,
    double screenY,
    Vector3 planeOrigin,
    Vector3 planeNormal,
  ) {
    if (camera.viewportWidth <= 0 || camera.viewportHeight <= 0) return null;
    final ndcX = screenX * 2 / camera.viewportWidth - 1;
    final ndcY = 1 - screenY * 2 / camera.viewportHeight;
    final inverse = camera.inverseViewProjectionMatrix;
    final near = inverse.transformPoint(Vector3(ndcX, ndcY, -1));
    final far = inverse.transformPoint(Vector3(ndcX, ndcY, 1));
    final direction = far - near;
    final denominator = planeNormal.dot(direction);
    if (denominator.abs() <= 1e-12) return null;
    final distance = planeNormal.dot(planeOrigin - near) / denominator;
    final point = near + direction * distance;
    return point.x.isFinite && point.y.isFinite && point.z.isFinite
        ? point
        : null;
  }
}
