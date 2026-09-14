import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/cad_viewport/rendering/stl_display_lod.dart';
import 'package:flcad_mobile/app/commands/desktop_command_coordinator.dart';
import 'package:flcad_mobile/app/desktop/desktop_cad_controller.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/import_export/import_export.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<String> digest(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

Future<void> grid(File file) async {
  const side = 360;
  final writer = file.openWrite();
  final header = ByteData(84)..setUint32(80, side * side * 2, Endian.little);
  writer.add(header.buffer.asUint8List());
  // Synthetic fixture emitted in bounded chunks; never an integral STL copy.
  for (var y = 0; y < side; y++) {
    final row = ByteData(side * 100);
    var offset = 0;
    for (var x = 0; x < side; x++) {
      for (final vertices in [
        [x, y, x + 1, y, x + 1, y + 1],
        [x, y, x + 1, y + 1, x, y + 1],
      ]) {
        row.setFloat32(offset + 8, 1, Endian.little);
        for (var corner = 0; corner < 3; corner++) {
          row.setFloat32(
            offset + 12 + corner * 12,
            vertices[corner * 2].toDouble(),
            Endian.little,
          );
          row.setFloat32(
            offset + 16 + corner * 12,
            vertices[corner * 2 + 1].toDouble(),
            Endian.little,
          );
        }
        offset += 50;
      }
    }
    writer.add(row.buffer.asUint8List());
    await writer.flush();
  }
  await writer.close();
}

// The real command must never reach the generic legacy import controller.
class _ManagedOnlyController extends DesktopCadController {
  _ManagedOnlyController({
    required super.kernels,
    required super.projects,
    required super.projectRepository,
    required super.managedStlFilePicker,
    required super.managedStlImporter,
  });
  @override
  Future<void> pickAndImport(CadImportFormat format) =>
      throw StateError('legacy controller import invoked');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final occ = Platform.environment['FLCAD_SOURCE_OCC_DLL'];
  final bridge = Platform.environment['FLCAD_SOURCE_BRIDGE_DLL'];
  test(
    'UI import.stl delivers managed LOD to host and preserves lifecycle',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad-dense-stl-');
      final generated = File(p.join(root.path, 'grid.stl'));
      await grid(generated);
      final external = Platform.environment['FLCAD_DENSE_STL_SOURCE'];
      final source = external == null ? generated : File(external);
      final sourceHash = await digest(source);
      final sourceSize = await source.length();
      final repository = ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final projects = ProjectManager(repository: repository);
      await projects.create(name: 'Dense STL', client: 'FLCAD');
      final projectId = projects.current!.id;
      final project = await repository.directoryFor(projectId);
      final adapter = OpenCascadeKernelAdapter(
        bridge: OpenCascadeFFI.load(path: occ!),
      );
      Future<String?> Function() pick = () async => source.path;
      late final DesktopCadController controller;
      controller = _ManagedOnlyController(
        kernels: KernelManager()..register(adapter, makeDefault: true),
        projects: projects,
        projectRepository: repository,
        managedStlImporter: (locator, cancellation) =>
            controller.runtime.importManagedStl(
              locator,
              cancellation: cancellation,
              nativeBridgePath: bridge,
            ),
        managedStlFilePicker: (extensions) {
          expect(extensions, ['stl']);
          return pick();
        },
      );
      final runtime = controller.runtime;
      final commands = DesktopCommandCoordinator(
        cad: controller,
        projects: projects,
        repository: repository,
      );
      await commands.refreshContext();
      try {
        await runtime.open(projectId, project);
        final previous = jsonEncode(runtime.document!.toJson());
        final previousScene = runtime.scene.entities.map((e) => e.id).toSet();
        // Cancel a real command while the picker is gated; no CAF admission.
        final gate = Completer<String?>();
        final entered = Completer<void>();
        pick = () {
          entered.complete();
          return gate.future;
        };
        final cancelled = commands.dispatch('import.stl');
        await entered.future;
        expect(controller.canCancelManagedImport, isTrue);
        controller.cancelManagedImport();
        gate.complete(source.path);
        await cancelled;
        expect(jsonEncode(runtime.document!.toJson()), previous);
        expect(runtime.scene.entities.map((e) => e.id).toSet(), previousScene);
        expect(runtime.managedImportPublication, isNull);
        // Admission failure preserves document/scene and exposes no locator.
        pick = () async => p.join(root.path, 'absent.stl');
        await commands.dispatch('import.stl');
        expect(jsonEncode(runtime.document!.toJson()), previous);
        expect(runtime.scene.entities.map((e) => e.id).toSet(), previousScene);
        expect(controller.message, isNot(contains(root.path)));
        pick = () async => source.path;
        await commands.dispatch('import.stl');
        expect(controller.progress, 1);
        final entity = runtime.document!.entities.values.singleWhere(
          (e) => e.data['managedStlAssets'] != null,
        );
        expect(entity.data['managedStlAssets'], isNotNull);
        expect(entity.data['registeredPath'], isNull);
        expect(runtime.activeImport, isNull);
        expect(runtime.geometrySelection.selectedIds, {entity.id});
        expect(runtime.managedImportPublication, isNotNull);
        final assets = ManagedStlAssets.fromJson(
          Map<String, dynamic>.from(entity.data['managedStlAssets'] as Map),
        );
        final payload = File(
          p.join(
            project.path,
            'CAD',
            'Assets',
            'v1',
            assets.display.value,
            'display.stl',
          ),
        );
        final durableHash = await digest(payload),
            durableSize = await payload.length();
        expect(durableHash, assets.displaySha256);
        final countBytes = await payload.openRead(80, 84).first;
        final durableTriangles = ByteData.sublistView(
          Uint8List.fromList(countBytes),
        ).getUint32(0, Endian.little);
        expect(durableTriangles, external == null ? 259200 : 1956958);
        expect(durableSize, 84 + durableTriangles * 50);
        final before = runtime.scene.find(entity.id)!.geometry;
        StlDisplayLod.preflight(before);
        final lod = before['presentationLod'] as Map;
        expect(lod['originalTriangles'], external == null ? 259200 : 1956958);
        expect(
          lod['displayTriangles'],
          lessThanOrEqualTo(StlDisplayLod.maxTriangles),
        );
        expect(
          lod['displayVertices'],
          lessThanOrEqualTo(StlDisplayLod.maxVertices),
        );
        final display = jsonEncode(before);
        final snapshot = CadSceneDisplayAdapter().initial(runtime.scene);
        expect(
          (snapshot.entities.firstWhere(
                    (e) => e['id'] == entity.id,
                  )['triangles']
                  as List)
              .length,
          (lod['displayTriangles'] as int) * 3,
        );
        // Exercise the actual channel boundary, not just camera/LOD math.
        Map<Object?, Object?>? delivered;
        const channel = MethodChannel('flcad/native_viewport');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'snapshot') {
                delivered = call.arguments as Map<Object?, Object?>;
              }
              return null;
            });
        final viewport = NativeViewportBridge()..available = true;
        await viewport.sendInitial(runtime.scene);
        expect(delivered, isNotNull);
        final hostEntity = (delivered!['entities'] as List)
            .cast<Map>()
            .firstWhere((e) => e['id'] == entity.id);
        expect(
          (hostEntity['nodes'] as List).length,
          (lod['displayVertices'] as int) * 3,
        );
        expect(
          (hostEntity['triangles'] as List).length,
          (lod['displayTriangles'] as int) * 3,
        );
        expect(hostEntity['presentationLod'], isNotNull);
        final methodBytes = const StandardMethodCodec().encodeMethodCall(
          MethodCall('snapshot', delivered),
        );
        expect(methodBytes.lengthInBytes, lessThan(24 * 1024 * 1024));
        stdout.writeln('ui-stl methodBytes=${methodBytes.lengthInBytes}');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        viewport.available = false;
        viewport.dispose();
        final output = Platform.environment['FLCAD_DENSE_STL_SNAPSHOT'];
        if (output != null) {
          final bytes = const StandardMessageCodec().encodeMessage(
            snapshot.toMessage(),
          )!;
          await File(output).writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        }
        stdout.writeln(
          'dense-stl original=${lod['originalTriangles']} display=${lod['displayTriangles']} vertices=${lod['displayVertices']} rss=${ProcessInfo.currentRss}',
        );
        for (var i = 0; i < 2; i++) {
          await runtime.undoDocument();
          expect(runtime.scene.find(entity.id), isNull);
          expect(adapter.custodyDiagnostics!.allocations, 0);
          await runtime.redoDocument();
          expect(jsonEncode(runtime.scene.find(entity.id)!.geometry), display);
          expect(adapter.custodyDiagnostics!.allocations, 1);
        }
        await runtime.transformManagedEntity(
          entity.id,
          translateX: 10,
          translateY: 20,
          translateZ: 30,
          rotateZ: 90,
        );
        final placed = jsonEncode(runtime.scene.find(entity.id)!.geometry);
        await runtime.save();
        final document = jsonEncode(runtime.document!.toJson());
        expect(document, isNot(contains('presentationLod')));
        expect(document, isNot(contains('spatial-clustering')));
        await runtime.close();
        await runtime.open(projectId, project);
        expect(jsonEncode(runtime.document!.toJson()), document);
        expect(jsonEncode(runtime.scene.find(entity.id)!.geometry), placed);
        expect(await digest(payload), durableHash);
        expect(await payload.length(), durableSize);
        expect(await digest(source), sourceHash);
        expect(await source.length(), sourceSize);
        expect(adapter.custodyDiagnostics!.leases, 0);
        stdout.writeln(
          'dense-stl lifecycle complete rss=${ProcessInfo.currentRss} peakRss=${ProcessInfo.maxRss}',
        );
      } finally {
        await runtime.shutdown();
        expect(adapter.custodyDiagnostics?.allocations ?? 0, 0);
        expect(adapter.custodyDiagnostics?.leases ?? 0, 0);
        controller.dispose();
        await adapter.unload();
        await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: occ == null || bridge == null
        ? 'Requires Windows native DLLs'
        : false,
  );
}
