abstract class CameraService {
  Future<void> initialize();

  Future<void> startPreview();

  Future<void> stopPreview();

  Future<String?> capturePhoto();

  Future<void> dispose();
}