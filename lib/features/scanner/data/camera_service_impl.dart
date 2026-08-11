import 'package:camera/camera.dart';

import '../domain/camera_service.dart';

class CameraServiceImpl implements CameraService {
  CameraController? _controller;

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
  Future<void> startPreview() async {}

  @override
  Future<void> stopPreview() async {}

  @override
  Future<String?> capturePhoto() async {
    return null;
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
  }
}