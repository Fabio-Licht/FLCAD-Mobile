import 'dart:io';

import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/surface_reconstruction_manager/surface_reconstruction_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const manager = SurfaceReconstructionManager();

  test('calculates area coverage and every region status', () {
    final state = manager.evaluate(
      _entities(),
      overrides: const {'Recognition003': ReconstructionRegionStatus.ignored},
    );
    final mesh = state.meshes.single;
    expect(mesh.totalArea, 100);
    expect(mesh.reconstructedArea, 30);
    expect(mesh.pendingArea, 20);
    expect(mesh.reconstructedPercent, 30);
    expect(mesh.pendingPercent, 20);
    expect(mesh.surfaceCount, 1);
    expect(mesh.pendingRegionCount, 1);
    expect(mesh.nextRegionId, 'Recognition002');
    expect(
      {
        for (final region in mesh.regions)
          region.recognitionResultId: region.status,
      },
      {
        'Recognition001': ReconstructionRegionStatus.reconstructed,
        'Recognition002': ReconstructionRegionStatus.inProgress,
        'Recognition003': ReconstructionRegionStatus.ignored,
      },
    );
  });

  test('publishes persistent per-triangle mesh colors', () {
    final regions = manager.evaluate(_entities()).meshes.single.regions;
    final first = regions.first;
    expect(first.triangleIndices, [0, 1, 2]);
    expect(first.color, 'green');
    expect(regions[1].color, 'yellow');
    expect(regions[2].color, 'red');
  });

  test('history records only real reconstruction transitions', () {
    final initial = manager.evaluate(_entities());
    final unchanged = manager.evaluate(_entities(), previous: initial);
    expect(
      unchanged.meshes.single.regions.first.history.length,
      initial.meshes.single.regions.first.history.length,
    );
    final ignored = manager.evaluate(
      _entities(),
      previous: unchanged,
      overrides: const {'Recognition002': ReconstructionRegionStatus.ignored},
    );
    final region = ignored.meshes.single.regions[1];
    expect(region.history.length, 2);
    expect(region.history.last.status, ReconstructionRegionStatus.ignored);
    expect(region.history.first.recognitionResultId, 'Recognition002');
  });

  test('coverage, overrides and history survive project reopen', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g140-');
    addTearDown(() => directory.delete(recursive: true));
    final runtime = CadRuntime(kernels: KernelManager());
    addTearDown(runtime.dispose);
    await runtime.open('project', directory);
    final state = manager.evaluate(
      _entities(),
      overrides: const {'Recognition003': ReconstructionRegionStatus.ignored},
    );
    await runtime.mutate(
      command: 'surface-reconstruction-manager.refresh',
      upsert: [
        CadDocumentEntity(
          id: 'SurfaceReconstructionManager',
          kind: CadDocumentEntityKind.collection,
          data: {
            'hiddenFromExplorer': true,
            'reconstructionState': state.toJson(),
            'overrides': {'Recognition003': 'ignored'},
            'sceneVisible': false,
          },
        ),
      ],
    );
    await runtime.save();
    await runtime.close();
    await runtime.open('project', directory);
    final restored =
        runtime.document!.entities['SurfaceReconstructionManager']!;
    final decoded = SurfaceReconstructionState.fromJson(
      Map<String, dynamic>.from(restored.data['reconstructionState'] as Map),
    );
    expect(decoded.meshes.single.reconstructedPercent, 30);
    expect(
      decoded.meshes.single.regions.last.status,
      ReconstructionRegionStatus.ignored,
    );
    expect(restored.data['overrides'], {'Recognition003': 'ignored'});
  });
}

List<CadDocumentEntity> _entities() => [
  const CadDocumentEntity(
    id: 'Mesh001',
    kind: CadDocumentEntityKind.import,
    data: {'name': 'Mesh001'},
  ),
  _recognition('Recognition001', 'region:Mesh001:0,1,2:0,1,2,3', 30, .96),
  _recognition('Recognition002', 'region:Mesh001:3,4:2,3,4', 20, .91),
  _recognition('Recognition003', 'region:Mesh001:5,6,7:5,6,7', 50, .70),
  const CadDocumentEntity(
    id: 'ReferenceCurve001',
    kind: CadDocumentEntityKind.section,
    data: {
      'references': ['Recognition002'],
    },
  ),
  const CadDocumentEntity(
    id: 'Surface001',
    kind: CadDocumentEntityKind.surface,
    data: {
      'references': ['Recognition001'],
    },
  ),
];

CadDocumentEntity _recognition(
  String id,
  String regionId,
  double area,
  double confidence,
) => CadDocumentEntity(
  id: id,
  kind: CadDocumentEntityKind.recognition,
  data: {
    'recognitionResult': {
      'schema': 'flcad.recognition-result',
      'version': 1,
      'id': id,
      'type': 'plane',
      'meshId': 'Mesh001',
      'regionId': regionId,
      'confidence': confidence,
      'parameters': {'area': area},
      'quality': 'validated',
      'suggestion': 'surface',
      'createdAt': DateTime.utc(2026).toIso8601String(),
      'history': const [],
    },
  },
);
