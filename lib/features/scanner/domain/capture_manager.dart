import 'package:camera/camera.dart';

import '../../../models/captured_image.dart';
import 'camera_service.dart';

class CaptureManager {
  CaptureManager({required this.cameraService});

  final CameraService cameraService;

  bool _capturing = false;

  bool get isCapturing => _capturing;

  Future<CapturedImage?> capture() async {
    if (_capturing) {
      return null;
    }

    _capturing = true;

    try {
      final XFile? file = await cameraService.capturePhoto();

      if (file == null) {
        return null;
      }

      return CapturedImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: file.path,
        capturedAt: DateTime.now(),
      );
    } finally {
      _capturing = false;
    }
  }
}
