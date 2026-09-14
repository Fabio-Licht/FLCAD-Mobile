import 'cad_camera_controller.dart';

/// Guards the single deferred Fit requested by a confirmed managed import.
/// Camera pose intentionally excludes viewport dimensions: layout may settle
/// between publication and the next frame, while user navigation may not be
/// overwritten.
final class CadManagedImportFitGate {
  int _ticket = 0;

  int schedule() => ++_ticket;

  bool canApply({
    required int ticket,
    required int publicationId,
    required int currentPublicationId,
    required int publicationSession,
    required int currentSession,
    required int publicationRevision,
    required int currentRevision,
    required CadCameraState scheduledCamera,
    required CadCameraController camera,
  }) =>
      ticket == _ticket &&
      publicationId == currentPublicationId &&
      publicationSession == currentSession &&
      publicationRevision == currentRevision &&
      camera.viewportWidth > 1 &&
      camera.viewportHeight > 1 &&
      _samePose(scheduledCamera, camera.snapshot());

  static bool _samePose(CadCameraState a, CadCameraState b) =>
      a.eye.x == b.eye.x &&
      a.eye.y == b.eye.y &&
      a.eye.z == b.eye.z &&
      a.target.x == b.target.x &&
      a.target.y == b.target.y &&
      a.target.z == b.target.z &&
      a.up.x == b.up.x &&
      a.up.y == b.up.y &&
      a.up.z == b.up.z &&
      a.projectionMode == b.projectionMode &&
      a.viewScale == b.viewScale &&
      a.fieldOfViewRadians == b.fieldOfViewRadians &&
      a.nearPlane == b.nearPlane &&
      a.farPlane == b.farPlane &&
      a.presentationTranslation.x == b.presentationTranslation.x &&
      a.presentationTranslation.y == b.presentationTranslation.y &&
      a.presentationTranslation.z == b.presentationTranslation.z &&
      a.presentationOffsetNdcX == b.presentationOffsetNdcX &&
      a.presentationOffsetNdcY == b.presentationOffsetNdcY;
}
