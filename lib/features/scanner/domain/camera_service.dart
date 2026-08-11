import 'package:camera/camera.dart';

abstract class CameraService {
  Future<void> initialize();

  Future<void> startPreview();

  Future<void> stopPreview();

  Future<XFile?> capturePhoto();

  Future<void> dispose();
}