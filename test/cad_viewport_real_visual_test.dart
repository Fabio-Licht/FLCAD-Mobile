import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/professional_cad_viewport_widget.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Explicit local discovery input is the real managed import's presentation
// geometry, not STEP source bytes or a managed asset. No persistent fixture.
void main() {
  final input = Platform.environment['FLCAD_VIEWPORT_CAPTURE_GEOMETRY'];
  final output = Platform.environment['FLCAD_VIEWPORT_CAPTURE_OUTPUT'];
  testWidgets(
    'capture real viewport after import Fit and across display modes',
    (tester) async {
      final geometry =
          jsonDecode(File(input!).readAsStringSync()) as Map<String, dynamic>;
      final bounds = (geometry['bounds'] as List).cast<num>();
      Vector3 point(int i) => Vector3(
        bounds[i].toDouble(),
        bounds[i + 1].toDouble(),
        bounds[i + 2].toDouble(),
      );
      final scene = CadSceneGraph();
      final camera = CadCameraController()..resize(900, 700);
      addTearDown(scene.dispose);
      addTearDown(camera.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      Future<void> captureFrame(String filename) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final directory = await Directory(output!).create(recursive: true);
          await File(
            '${directory.path}/$filename.png',
          ).writeAsBytes(data!.buffer.asUint8List());
        });
      }

      scene.upsert(
        CadSceneEntity(
          id: 'visual',
          kind: CadSceneEntityKind.mesh,
          geometry: geometry,
        ),
      );
      var fitted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: RepaintBoundary(
            key: key,
            child: ProfessionalCadViewportWidget(
              scene: scene,
              camera: camera,
              enablePicking: false,
              onViewportReady: () {
                if (fitted) return;
                fitted = true;
                camera.fit(point(0), point(3));
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(fitted, isTrue);
      await captureFrame('import-fitted');
      for (final view in [
        CadStandardView.top,
        CadStandardView.bottom,
        CadStandardView.isometric,
      ]) {
        camera.fit(point(0), point(3));
        camera.setStandardView(view, point(0), point(3));
        for (final mode in [
          CadRenderStyle.shaded,
          CadRenderStyle.hiddenLine,
          CadRenderStyle.transparent,
        ]) {
          for (final selected in [false, true]) {
            scene.replaceAll([
              CadSceneEntity(
                id: 'visual',
                kind: CadSceneEntityKind.mesh,
                geometry: geometry,
                selected: selected,
              ),
            ]);
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData.dark(),
                home: RepaintBoundary(
                  key: key,
                  child: ProfessionalCadViewportWidget(
                    scene: scene,
                    camera: camera,
                    renderStyle: mode,
                    showRenderControls: false,
                    enablePicking: false,
                  ),
                ),
              ),
            );
            await tester.pump();
            await captureFrame(
              '${view.name}-${mode.name}-${selected ? 'selected' : 'plain'}',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
    skip: input == null || output == null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
