import '../../../models/scan_session.dart';

class CaptureManager {
  CaptureManager(this.session);

  final ScanSession session;

  bool _capturing = false;

  bool get isCapturing => _capturing;

  void startCapture() {
    _capturing = true;
  }

  void stopCapture() {
    _capturing = false;
  }
}