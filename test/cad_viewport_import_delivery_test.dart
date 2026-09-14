import 'dart:async';
import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/camera/cad_managed_import_fit.dart';
import 'package:flcad_mobile/app/cad_viewport/native/integrated_native_viewport_widget.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'publication waits for real viewport layout and host snapshot, then delivers Fit once',
    (tester) async {
      const channel = MethodChannel('flcad/native_viewport');
      final initialized = Completer<int>();
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'initialize') return initialized.future;
        if (call.method == 'pick') {
          return {
            'entityId': 'part',
            'kind': 1,
            'subId': 1,
            'point': [10.0, 20.0, 0.0],
          };
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final scene = CadSceneGraph()
        ..upsert(
          CadSceneEntity(
            id: 'part',
            kind: CadSceneEntityKind.mesh,
            geometry: {
              'nodes': [10.0, 20.0, 0.0, 30.0, 20.0, 0.0, 10.0, 40.0, 0.0],
              'triangles': [0, 1, 2],
              'bounds': [10.0, 20.0, 0.0, 30.0, 40.0, 0.0],
            },
          ),
        );
      final camera = CadCameraController();
      addTearDown(scene.dispose);
      addTearDown(camera.dispose);
      // Controller restoration precedes admission of the Fit request, exactly
      // as in the real workspace. Host initialization is deterministically held.
      camera.restoreWorkspace(
        const Vector3(10, 20, 0),
        const Vector3(30, 40, 0),
      );
      final gate = CadManagedImportFitGate();
      final ticket = gate.schedule();
      final pose = camera.snapshot();
      var pending = true;
      var delivered = 0;
      Widget viewport() => MaterialApp(
        home: IntegratedCadViewportWidget(
          scene: scene,
          camera: camera,
          onViewportReady: () {
            if (!pending) return;
            expect(
              gate.canApply(
                ticket: ticket,
                publicationId: 1,
                currentPublicationId: 1,
                publicationSession: 1,
                currentSession: 1,
                publicationRevision: 1,
                currentRevision: 1,
                scheduledCamera: pose,
                camera: camera,
              ),
              isTrue,
            );
            pending = false;
            delivered++;
            camera.fit(const Vector3(10, 20, 0), const Vector3(30, 40, 0));
          },
        ),
      );
      await tester.pumpWidget(viewport());
      await tester.pump();
      expect(delivered, 0);
      await tester.pumpWidget(
        viewport(),
      ); // Rebuild cannot consume the request.
      initialized.complete(42);
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(delivered, 1);
      final snapshot = calls.indexWhere((c) => c.method == 'snapshot');
      expect(snapshot, greaterThanOrEqualTo(0));
      final cameras = calls
          .skip(snapshot + 1)
          .where((c) => c.method == 'setCamera')
          .toList();
      expect(cameras, isNotEmpty);
      final deliveredCamera = cameras.last.arguments as Map;
      expect(deliveredCamera['target'], [20.0, 30.0, 0.0]);
      expect(deliveredCamera['eye'], [
        camera.presentationEye.x,
        camera.presentationEye.y,
        camera.presentationEye.z,
      ]);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(300, 300));
      await mouse.moveTo(const Offset(310, 310));
      await tester.pump();
      expect(calls.where((c) => c.method == 'setOperationalHover'), isEmpty);
      expect(find.text('Mesh Region'), findsNothing);
      camera.pan(10, 0);
      final userEye = camera.eye;
      await tester.pumpWidget(viewport());
      await tester.pump();
      expect(delivered, 1);
      expect(camera.eye, userEye);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
    skip: !Platform.isWindows,
  );
}
