import 'package:camera/camera.dart';

abstract class CameraService {
  CameraController? get controller;

  Future<void> initialize();

  Future<void> startPreview();

  Future<void> stopPreview();

  Future<XFile?> capturePhoto();

  Future<double> getMinZoomLevel();

  Future<double> getMaxZoomLevel();

  Future<void> setZoomLevel(double zoom);

  Future<void> dispose();
}
