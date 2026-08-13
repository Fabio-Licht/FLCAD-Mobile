import 'package:camera/camera.dart';

import '../domain/camera_service.dart';
import '../../../core/logger/app_logger.dart';

class CameraServiceImpl implements CameraService {
  CameraController? _controller;

  @override
  CameraController? get controller => _controller;

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('Nenhuma câmera encontrada.');
    }

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  @override
  Future<void> startPreview() async {
    // O preview é iniciado automaticamente pelo CameraController.initialize()
  }

  @override
  Future<void> stopPreview() async {
    // Implementação futura (caso seja necessário pausar o preview)
  }

  @override
  Future<XFile?> capturePhoto() async {
    if (_controller == null) {
      return null;
    }

    if (!_controller!.value.isInitialized) {
      return null;
    }

    if (_controller!.value.isTakingPicture) {
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      return image;
    } catch (error, stackTrace) {
      AppLogger.log(
        'Camera capture failed',
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<double> getMinZoomLevel() => _controller!.getMinZoomLevel();

  @override
  Future<double> getMaxZoomLevel() => _controller!.getMaxZoomLevel();

  @override
  Future<void> setZoomLevel(double zoom) => _controller!.setZoomLevel(zoom);

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
