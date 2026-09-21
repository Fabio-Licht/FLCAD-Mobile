import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/cad_viewport/rendering/cad_root_color.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_document/cad_document_repository.dart';
import 'package:flcad_mobile/core/cad_document/alignment_coordinate_system.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_kernel/linear_algebra/matrices.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _Storage extends CadAssetStorage {
  Future<void> Function(String)? gate;
  @override
  Future<void> checkpoint(String phase) async {
    await gate?.call(phase);
  }
}

class _Repository extends CadDocumentRepository {
  bool reject = false;
  @override
  Future<void> save(CadDocument document, Directory project) {
    if (reject) throw StateError('injected:placement:persistence');
    return super.save(document, project);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final caf = Platform.environment['FLCAD_CAD_ASSET_FS_DLL']!;
  final occ = Platform.environment['FLCAD_SOURCE_OCC_DLL']!;
  final bridge = Platform.environment['FLCAD_SOURCE_BRIDGE_DLL']!;
  late Directory root, source, project;
  late CadRuntime runtime;
  late OpenCascadeKernelAdapter adapter;
  late _Storage storage;
  late _Repository repository;
  late int Function() pathImports;

  Future<CadDocumentEntity> import(String kind) => switch (kind) {
    'step' => runtime.importManagedStep(
      p.join(source.path, 'part-0.step'),
      nativeBridgePath: bridge,
    ),
    'brep' => runtime.importManagedBrep(
      p.join(source.path, 'shape.brep'),
      nativeBridgePath: bridge,
    ),
    _ => runtime.importManagedStl(
      p.join(source.path, 'ascii.stl'),
      nativeBridgePath: bridge,
    ),
  };
  Map<String, String> inventory() {
    final dir = Directory(p.join(project.path, 'CAD', 'Assets'));
    return {
      for (final file in dir.listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: dir.path):
            '${file.lengthSync()}:${sha256.convert(file.readAsBytesSync())}',
    };
  }

  String system(String suffix) => runtime.document!.entities.keys.singleWhere(
    (id) => id.endsWith(':world:$suffix'),
  );

  String visual() =>
      jsonEncode({for (final e in runtime.scene.entities) e.id: e.geometry});
  void drained(int owners) {
    expect(adapter.custodyDiagnostics!.allocations, owners);
    expect(adapter.custodyDiagnostics!.leases, 0);
    expect(pathImports(), 0);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('managed-placement-');
    source = await Directory.systemTemp.createTemp('cob-dart-placement-');
    project = await Directory(p.join(root.path, 'project')).create();
    for (final entry in [
      (
        Platform.environment['FLCAD_SOURCE_FIXTURE_EXE']!,
        [caf, occ, source.path],
      ),
      (
        Platform.environment['FLCAD_STEP_FIXTURE_EXE']!,
        [caf, bridge, source.path],
      ),
    ]) {
      final generated = await Process.run(entry.$1, entry.$2);
      expect(
        generated.exitCode,
        0,
        reason: '${generated.stdout}\n${generated.stderr}',
      );
    }
    await File(p.join(source.path, 'ascii.stl')).writeAsString(
      'solid sample\nfacet normal 0 0 1\nouter loop\nvertex 0 0 0\nvertex 1 0 0\nvertex 0 1 0\nendloop\nendfacet\nendsolid sample\n',
    );
    adapter = OpenCascadeKernelAdapter(bridge: OpenCascadeFFI.load(path: occ));
    storage = _Storage();
    repository = _Repository();
    runtime = CadRuntime(
      kernels: KernelManager()..register(adapter, makeDefault: true),
      assetStorage: storage,
      repository: repository,
    );
    await runtime.open('placement-project', project);
    pathImports = DynamicLibrary.open(occ)
        .lookupFunction<Uint64 Function(), int Function()>(
          'flcad_occ_test_path_import_count',
        );
  });
  tearDown(() async {
    storage.gate = null;
    repository.reject = false;
    await runtime.shutdown();
    drained(0);
    await adapter.unload();
    await root.delete(recursive: true);
    await source.delete(recursive: true);
  });

  for (final kind in ['step', 'brep', 'stl']) {
    test(
      '$kind rigid placement preserves assets, presentation, owners and persistent history',
      () async {
        final e = await import(kind);
        runtime.select({e.id});
        final assets = inventory();
        final original = runtime.scene.find(e.id)!.geometry;
        final rgb = cadRootSrgb(original);
        final localNodes = (original['nodes'] as List).cast<num>();
        final owners = kind == 'stl' ? 1 : 2;
        final residence = runtime.managedGeometryDiagnostics(e.id);
        await runtime.transformManagedEntity(
          e.id,
          translateX: 10,
          translateY: -2,
          rotateZ: 90,
        );
        final placed = runtime.document!.entities[e.id]!;
        expect(
          Map.of(placed.data)..remove('featureLifecycle'),
          Map.of(e.data)..remove('featureLifecycle'),
        );
        final expected = placed.placement!.matrix.transformPoint(
          Vector3(
            localNodes[0].toDouble(),
            localNodes[1].toDouble(),
            localNodes[2].toDouble(),
          ),
        );
        final g = runtime.scene.find(e.id)!.geometry;
        expect((g['nodes'] as List)[0], closeTo(expected.x, 1e-8));
        expect((g['nodes'] as List)[1], closeTo(expected.y, 1e-8));
        expect(cadRootSrgb(g), rgb);
        final host = CadSceneDisplayAdapter()
            .initial(runtime.scene)
            .entities
            .singleWhere((x) => x['id'] == e.id);
        expect(
          host['nodes'],
          kind == 'stl' ? g['nodes'] : (g['brepPresentation'] as Map)['nodes'],
        );
        expect(runtime.selection, {e.id});
        expect(runtime.managedGeometryDiagnostics(e.id), residence);
        drained(owners);
        final confirmed = visual();
        for (var i = 0; i < 3; i++) {
          await runtime.undoDocument();
          expect(runtime.document!.entities[e.id]!.placement, isNull);
          expect(
            runtime.scene.find(e.id)!.geometry['nodes'],
            original['nodes'],
          );
          drained(owners);
          await runtime.redoDocument();
          expect(visual(), confirmed);
          expect(runtime.managedGeometryDiagnostics(e.id), residence);
          drained(owners);
        }
        await runtime.save();
        await runtime.close();
        drained(0);
        await runtime.open('placement-project', project);
        expect(visual(), confirmed);
        drained(owners);
        await runtime.undoDocument();
        expect(runtime.document!.entities[e.id]!.placement, isNull);
        await runtime.redoDocument();
        expect(visual(), confirmed);
        await runtime.resetManagedPlacement(e.id);
        expect(runtime.document!.entities[e.id]!.placement, isNull);
        expect(runtime.scene.find(e.id)!.geometry['nodes'], original['nodes']);
        await runtime.undoDocument();
        expect(visual(), confirmed);
        if (kind != 'step') {
          await runtime.setEntityVisibility(e.id, false);
          expect(
            runtime.document!.entities[e.id]!.placement!.toJson(),
            placed.placement!.toJson(),
          );
          await runtime.undoDocument();
        }
        expect(inventory(), assets);
        final json = runtime.document!.entities[e.id]!.toJson();
        expect(json['shape'], isNull);
        expect(json['mesh'], isNull);
        expect((json['placement'] as Map).keys, isNot(contains('pointer')));
      },
    );
  }
  test(
    'G105A2 previews and applies a WCS placement without changing CAF assets',
    () async {
      final entity = await import('step');
      final assets = inventory();
      final wcs = await runtime.createAlignmentCoordinateSystemReference(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('y-axis'),
        originKind: AlignmentCoordinateSystemOriginKind.manual,
        manualOrigin: const Vector3(25, -40, 12.5),
      );
      final before = runtime.document!.toJson();
      final preview = await runtime.previewManagedAlignment(
        entityId: entity.id,
        coordinateSystemId: wcs,
      );
      expect(runtime.document!.toJson(), before);
      expect(
        runtime.scene.find('alignment-wcs-preview-${entity.id}'),
        isNotNull,
      );
      expect(preview.placement.matrix.transformPoint(Vector3.zero).toJson(), [
        25.0,
        -40.0,
        12.5,
      ]);
      runtime.clearManagedAlignmentPreview();
      expect(runtime.scene.find('alignment-wcs-preview-${entity.id}'), isNull);

      await runtime.applyManagedAlignment(
        entityId: entity.id,
        coordinateSystemId: wcs,
        createWorkingCopy: false,
      );
      final placed = runtime.document!.entities[entity.id]!;
      expect(placed.placement!.matrix.transformPoint(Vector3.zero).toJson(), [
        25.0,
        -40.0,
        12.5,
      ]);
      expect(placed.data['alignmentByCoordinateSystem'], isA<Map>());
      expect(inventory(), assets);
      await runtime.undoDocument();
      expect(runtime.document!.entities[entity.id]!.placement, isNull);
      await runtime.redoDocument();
      expect(runtime.document!.entities[entity.id]!.placement, isNotNull);

      final copy = await runtime.applyManagedAlignment(
        entityId: entity.id,
        coordinateSystemId: wcs,
        createWorkingCopy: true,
      );
      expect(copy, isNot(entity.id));
      expect(runtime.document!.entities[entity.id], isNotNull);
      expect(
        runtime.document!.entities[copy]!.data['collectionId'],
        'collection:working-copy',
      );
      expect(inventory(), assets);
      await runtime.save();
      await runtime.close();
      await runtime.open('placement-project', project);
      expect(runtime.document!.entities[copy], isNotNull);
    },
  );
  test(
    'mixed legacy/STEP/BREP/STL history transforms only target and restores atomically',
    () async {
      final a = await import('step');
      final b = await import('brep');
      final c = await import('stl');
      await runtime.mutate(
        command: 'legacy.add',
        upsert: [
          const CadDocumentEntity(
            id: 'legacy',
            kind: CadDocumentEntityKind.curve,
            data: {
              'sceneKind': 'curve',
              'sceneGeometry': {
                'points': [
                  [0, 0, 0],
                  [1, 0, 0],
                ],
              },
            },
          ),
        ],
      );
      final before = visual();
      final assets = inventory();
      await runtime.transformManagedEntity(a.id, translateX: 4);
      final first = visual();
      await runtime.transformManagedEntity(c.id, rotateX: 30);
      expect(runtime.document!.entities[b.id]!.placement, isNull);
      expect(runtime.document!.entities['legacy']!.placement, isNull);
      await runtime.undoDocument();
      expect(visual(), first);
      await runtime.undoDocument();
      expect(visual(), before);
      await runtime.redoDocument();
      expect(visual(), first);
      await runtime.redoDocument();
      drained(5);
      expect(inventory(), assets);
    },
  );
  test(
    'precommit persistence failure keeps complete prior state and custody',
    () async {
      final e = await import('step');
      runtime.select({e.id});
      await runtime.transformManagedEntity(e.id, translateX: 2);
      final document = runtime.document!.toJson(),
          before = visual(),
          assets = inventory();
      final history = File(
        p.join(project.path, 'cad-document-history.json'),
      ).readAsStringSync();
      repository.reject = true;
      await expectLater(
        runtime.transformManagedEntity(e.id, rotateY: 45),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'cause',
            'injected:placement:persistence',
          ),
        ),
      );
      expect(runtime.document!.toJson(), document);
      expect(visual(), before);
      expect(runtime.selection, {e.id});
      expect(
        File(
          p.join(project.path, 'cad-document-history.json'),
        ).readAsStringSync(),
        history,
      );
      expect(inventory(), assets);
      drained(2);
    },
  );
  for (final action in ['close', 'open', 'shutdown']) {
    test(
      '$action revokes a prepared placement without late publication',
      () async {
        final e = await import('step');
        final assets = inventory();
        final reached = Completer<void>(), release = Completer<void>();
        storage.gate = (phase) async {
          if (phase == 'managedHistory:beforePublish') {
            reached.complete();
            await release.future;
          }
        };
        final pending = runtime.transformManagedEntity(e.id, translateX: 200);
        final assertion = expectLater(
          pending,
          throwsA(isA<StaleCadTransaction>()),
        );
        await reached.future;
        final Future<void> boundary = switch (action) {
          'close' => runtime.close(),
          'open' => runtime.open(
            'replacement',
            await Directory(p.join(root.path, 'replacement')).create(),
          ),
          _ => runtime.shutdown(),
        };
        release.complete();
        await assertion;
        await boundary;
        if (action == 'shutdown') {
          expect(runtime.document!.entities[e.id]!.placement, isNull);
        } else {
          expect(runtime.document?.entities[e.id], isNull);
        }
        drained(0);
        expect(inventory(), assets);
      },
    );
  }
  test(
    'nonfinite input and legacy destructive path reject without side effects',
    () async {
      final e = await import('brep');
      final before = visual();
      final document = runtime.document!.toJson();
      await expectLater(
        runtime.transformManagedEntity(e.id, rotateZ: double.nan),
        throwsFormatException,
      );
      await expectLater(
        runtime.applyEntityTransform({e.id}, Matrix4.identity()),
        throwsUnsupportedError,
      );
      expect(runtime.document!.toJson(), document);
      expect(visual(), before);
      drained(2);
    },
  );
  test(
    'invalid placement in open and Redo history fails before publication',
    () async {
      final e = await import('step');
      await runtime.transformManagedEntity(e.id, translateX: 5);
      await runtime.undoDocument();
      final prior = runtime.document!.toJson();
      final priorVisual = visual();
      final assets = inventory();
      final historyFile = File(
        p.join(project.path, 'cad-document-history.json'),
      );
      final history = jsonDecode(historyFile.readAsStringSync()) as Map;
      final redo = (history['redo'] as List).last as Map;
      final encoded =
          (redo['entities'] as List).singleWhere((x) => x['id'] == e.id) as Map;
      (encoded['placement'] as Map)['operations'] = [
        {
          'kind': 'scale',
          'values': [0, 0, 0],
        },
      ];
      await historyFile.writeAsString(jsonEncode(history));
      await expectLater(
        runtime.open('placement-project', project),
        throwsFormatException,
      );
      expect(runtime.document!.toJson(), prior);
      expect(visual(), priorVisual);
      drained(2);
      // The in-memory, already-validated Redo snapshot is independent of bad disk history.
      await runtime.redoDocument();
      expect(runtime.document!.entities[e.id]!.placement, isNotNull);
      await runtime.save();
      final file = File(p.join(project.path, 'cad-document.json'));
      final document = jsonDecode(file.readAsStringSync()) as Map;
      final entity =
          (document['entities'] as List).singleWhere((x) => x['id'] == e.id)
              as Map;
      (entity['placement'] as Map)['version'] = 99;
      final confirmed = runtime.document!.toJson(), confirmedVisual = visual();
      await file.writeAsString(jsonEncode(document));
      await expectLater(
        runtime.open('placement-project', project),
        throwsFormatException,
      );
      expect(runtime.document!.toJson(), confirmed);
      expect(visual(), confirmedVisual);
      expect(inventory(), assets);
      drained(2);
      // Restore valid persistence before shutdown performs its normal save.
      await runtime.save();
    },
  );
}
