import 'viewport_camera.dart';

class ViewportNavigation {
  ViewportCamera camera = const ViewportCamera();
  void orbit(double dx, double dy) => camera = camera.orbit(dx, dy);
  void pan(double dx, double dy) => camera = camera.pan(dx, dy);
  void zoom(double factor) => camera = camera.scale(factor);
  void fit() => camera = const ViewportCamera();
}
