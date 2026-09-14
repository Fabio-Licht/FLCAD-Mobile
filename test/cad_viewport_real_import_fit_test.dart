import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/app/commands/desktop_command_coordinator.dart';
import 'package:flcad_mobile/app/desktop/desktop_application.dart';
import 'package:flcad_mobile/app/desktop/desktop_cad_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/professional_cad_viewport_widget.dart';
import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = Platform.environment['FLCAD_REAL_STEP_SOURCE'];
  testWidgets(
    'real managed-only STEP publication delivers Fit through Official workspace and Professional viewport to host',
    (tester) async {
      const channel = MethodChannel('flcad/native_viewport');
      final calls = <MethodCall>[];
      final initialCameraDelivered = Completer<void>();
      final fitDelivered = Completer<void>();
      var importCommitted = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'setCamera') {
          if (!initialCameraDelivered.isCompleted) {
            initialCameraDelivered.complete();
          }
          if (importCommitted && !fitDelivered.isCompleted) {
            fitDelivered.complete();
          }
        }
        if (call.method == 'initialize') return 42;
        return null;
      });
      EngineeringBootstrap.instance.initialize();
      late Directory root;
      late DesktopCadController cad;
      late DesktopCommandCoordinator commands;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('viewport-real-fit-');
        final repository = ProjectRepository(
          storage: LocalStorageService(rootDirectory: root),
        );
        final projects = ProjectManager(repository: repository);
        final project = await projects.create(
          name: 'Viewport regression',
          client: 'Test',
        );
        final adapter = OpenCascadeKernelAdapter(
          bridge: OpenCascadeFFI.load(
            path: Platform.environment['FLCAD_SOURCE_OCC_DLL']!,
          ),
        );
        cad = DesktopCadController(
          kernels: KernelManager()..register(adapter, makeDefault: true),
          projects: projects,
          projectRepository: repository,
          managedStepFilePicker: (_) async => source,
          managedStepImporter: (locator, cancellation) =>
              cad.runtime.importManagedStep(
                locator,
                cancellation: cancellation,
                nativeBridgePath:
                    Platform.environment['FLCAD_SOURCE_BRIDGE_DLL'],
              ),
        );
        commands = DesktopCommandCoordinator(
          cad: cad,
          projects: projects,
          repository: repository,
        );
        await cad.runtime.open(
          project.id,
          await repository.directoryFor(project.id),
        );
      });
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        paths,
        (_) async => root.path,
      );
      final logs = <String>[];
      final captureKey = GlobalKey();
      Widget officialWorkspace() => MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: captureKey,
            child: OfficialEngineeringWorkspace(cad: cad, commands: commands),
          ),
        ),
      );
      final originalDebugPrint = debugPrint;
      debugPrint = (String? text, {int? wrapWidth}) {
        if (text != null) logs.add(text);
      };
      try {
        await tester.pumpWidget(officialWorkspace());
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }
        await tester.runAsync(() => initialCameraDelivered.future);
        await tester.runAsync(cad.pickAndImportManagedStep);
        importCommitted = true;
        expect(
          cad.document,
          isNull,
          reason:
              'Managed-only imports deliberately have no legacy activeImport',
        );
        expect(cad.runtime.managedImportPublication, isNotNull);
        for (var i = 0; i < 10; i++) {
          await tester.pump();
        }
        await tester.runAsync(() => fitDelivered.future);
        await tester.pump();
        final viewport = tester.widget<ProfessionalCadViewportWidget>(
          find.byType(ProfessionalCadViewportWidget),
        );
        final bounds = cad.runtime.managedImportPublication!.bounds;
        final expectedTarget = [
          (bounds.minX + bounds.maxX) / 2,
          (bounds.minY + bounds.maxY) / 2,
          (bounds.minZ + bounds.maxZ) / 2,
        ];
        expect([
          viewport.camera.target.x,
          viewport.camera.target.y,
          viewport.camera.target.z,
        ], expectedTarget);
        final cameraCalls = calls
            .where((c) => c.method == 'setCamera')
            .toList();
        expect(cameraCalls, isNotEmpty);
        expect((cameraCalls.last.arguments as Map)['target'], expectedTarget);
        expect(
          logs.where(
            (s) => s.contains('valid viewport presented; Fit delivered'),
          ),
          hasLength(1),
        );
        expect(logs.join(), isNot(contains(source!)));
        final output = Platform.environment['FLCAD_VIEWPORT_CAPTURE_OUTPUT'];
        if (output != null) {
          // Native command delivery was verified above. Paint the same fitted
          // camera with the real Canvas backend for a test-window capture.
          await tester.tap(find.text('Flutter Canvas'));
          await tester.pump();
          expect(
            tester
                .widget<ProfessionalCadViewportWidget>(
                  find.byType(ProfessionalCadViewportWidget),
                )
                .renderMeshes,
            isTrue,
          );
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final pixels = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            var materialPixels = 0;
            for (var y = 200; y < image.height - 50; y++) {
              for (var x = 250; x < 1250; x++) {
                final i = (y * image.width + x) * 4;
                if (pixels!.getUint8(i + 2) > pixels.getUint8(i) + 10 &&
                    pixels.getUint8(i) > 30 &&
                    pixels.getUint8(i + 1) > 50) {
                  materialPixels++;
                }
              }
            }
            expect(
              materialPixels,
              greaterThan(1000),
              reason:
                  'The actual fitted workspace must paint the imported solid after switching backend',
            );
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            await Directory(output).create(recursive: true);
            await File(
              '$output/official-import-fitted.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
        await tester.pumpWidget(officialWorkspace());
        await tester.pump();
        expect(
          logs.where(
            (s) => s.contains('valid viewport presented; Fit delivered'),
          ),
          hasLength(1),
        );
      } finally {
        await tester.runAsync(() async {
          for (final entity in cad.runtime.scene.entities) {
            await cad.runtime.operationalResolver.resolve(
              NativeViewportPick(
                entityId: entity.id,
                kind: NativePickKind.face,
                subId: 1,
                point: const [0, 0, 0],
              ),
              cad.runtime.scene,
            );
          }
        });
        await tester.pumpWidget(const SizedBox());
        debugPrint = originalDebugPrint;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          paths,
          null,
        );
        await tester.binding.setSurfaceSize(null);
        await tester.runAsync(() async {
          await cad.runtime.shutdown();
          cad.dispose();
          await root.delete(recursive: true);
        });
      }
    },
    skip: source == null || !Platform.isWindows,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
