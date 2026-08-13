import '../../../models/captured_image.dart';
import '../../../models/scan_session.dart';

class ScanSessionManager {
  ScanSessionManager({required ScanSession session}) : _session = session;

  ScanSession _session;

  ScanSession get session => _session;

  List<CapturedImage> get images => _session.images;

  int get imageCount => images.length;

  void addImage(CapturedImage image) {
    _session = _session.copyWith(images: [..._session.images, image]);
  }

  void removeImage(String imageId) {
    _session = _session.copyWith(
      images: _session.images.where((image) => image.id != imageId).toList(),
    );
  }

  void rename(String name) {
    _session = _session.copyWith(name: name);
  }

  void updateStatus(ScanSessionStatus status) {
    _session = _session.copyWith(status: status);
  }

  void finish() {
    _session = _session.copyWith(status: ScanSessionStatus.completed);
  }
}
