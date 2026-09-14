import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/camera/cad_managed_import_fit.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CadCameraController readyCamera() => CadCameraController()..resize(1000, 700);

  test(
    'confirmed publication fits only while its camera and runtime remain current',
    () {
      final camera = readyCamera();
      addTearDown(camera.dispose);
      final gate = CadManagedImportFitGate();
      final ticket = gate.schedule();
      final before = camera.snapshot();

      expect(
        gate.canApply(
          ticket: ticket,
          publicationId: 4,
          currentPublicationId: 4,
          publicationSession: 7,
          currentSession: 7,
          publicationRevision: 9,
          currentRevision: 9,
          scheduledCamera: before,
          camera: camera,
        ),
        isTrue,
      );

      camera.pan(15, -8);
      expect(
        gate.canApply(
          ticket: ticket,
          publicationId: 4,
          currentPublicationId: 4,
          publicationSession: 7,
          currentSession: 7,
          publicationRevision: 9,
          currentRevision: 9,
          scheduledCamera: before,
          camera: camera,
        ),
        isFalse,
        reason: 'user navigation must win over a queued Fit',
      );
    },
  );

  test(
    'cancelled, open, undo, redo and superseded publications cannot fit',
    () {
      final camera = readyCamera();
      addTearDown(camera.dispose);
      final gate = CadManagedImportFitGate();
      final ticket = gate.schedule();
      final before = camera.snapshot();

      bool eligible({
        required int currentPublication,
        required int currentSession,
        required int currentRevision,
      }) => gate.canApply(
        ticket: ticket,
        publicationId: 4,
        currentPublicationId: currentPublication,
        publicationSession: 7,
        currentSession: currentSession,
        publicationRevision: 9,
        currentRevision: currentRevision,
        scheduledCamera: before,
        camera: camera,
      );

      expect(
        eligible(currentPublication: 0, currentSession: 7, currentRevision: 9),
        isFalse,
      );
      expect(
        eligible(currentPublication: 5, currentSession: 7, currentRevision: 9),
        isFalse,
      );
      expect(
        eligible(currentPublication: 4, currentSession: 8, currentRevision: 9),
        isFalse,
      );
      expect(
        eligible(currentPublication: 4, currentSession: 7, currentRevision: 10),
        isFalse,
      );
    },
  );

  test('Fit uses the published scene bounds after the gate allows it', () {
    final camera = readyCamera();
    addTearDown(camera.dispose);
    final gate = CadManagedImportFitGate();
    final ticket = gate.schedule();
    final before = camera.snapshot();
    expect(
      gate.canApply(
        ticket: ticket,
        publicationId: 1,
        currentPublicationId: 1,
        publicationSession: 1,
        currentSession: 1,
        publicationRevision: 1,
        currentRevision: 1,
        scheduledCamera: before,
        camera: camera,
      ),
      isTrue,
    );
    camera.fit(const Vector3(-10, -20, -30), const Vector3(10, 20, 30));
    expect(camera.target, isNotNull);
    expect(camera.target.x, 0);
    expect(camera.target.y, 0);
    expect(camera.target.z, 0);
  });
}
