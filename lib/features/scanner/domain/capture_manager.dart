import 'package:camera/camera.dart';

import '../../../models/captured_image.dart';
import '../../../models/scan_session.dart';
import 'camera_service.dart';

class CaptureManager {
  CaptureManager({
    required this.session,
    required this.cameraService,
  });

  final ScanSession session;
  final CameraService cameraService;

  bool _capturing = false;

  bool get isCapturing => _capturing;

  void startCapture() {
    _capturing = true;
  }

  void stopCapture() {
    _capturing = false;
  }

  Future<CapturedImage?> capture() async {
    final XFile? file = await cameraService.capturePhoto();

    if (file == null) {
      return null;
    }

    return CapturedImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: file.path,
      capturedAt: DateTime.now(),
    );
  }
}