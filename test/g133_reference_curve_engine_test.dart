import 'dart:io';

import 'package:flcad_mobile/app/engineering_bridge/selection/section_manager.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/app/runtime/world_coordinate_system.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/feature_lifecycle/feature_lifecycle.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/import_export/api/import_export_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Reference Curve remains live, localized and persistent', () async {
    final directory = await Directory.systemTemp.createTemp('flcad_g133_');
    addTearDown(() => directory.delete(recursive: true));
    final runtime = CadRuntime(kernels: KernelManager());
    addTearDown(runtime.dispose);
    await runtime.open('project', directory);
    const mesh = KernelMeshHandle(
      persistentId: 'mesh-shape',
      kernelId: 'test',
      fingerprint: 'mesh',
      vertexCount: 4,
      triangleCount: 4,
      bounds: KernelBounds(-1, -1, -1, 1, 1, 1),
      hasNormals: false,
      metadata: {},
    );
    await runtime.registerImport(
      const ImportedCadDocument(
        id: 'Mesh001',
        projectId: 'project',
        sourcePath: 'mesh.stl',
        format: CadImportFormat.stl,
        registeredPath: 'CAD/Imports/mesh.stl',
        validation: [],
        mesh: mesh,
      ),
      geometry: const KernelMeshGeometry(
        nodes: [-1, -1, -1, 1, -1, 1, 0, 1, -1, 0, 0, 1],
        triangles: [0, 1, 2, 0, 3, 1, 1, 3, 2, 2, 3, 0],
      ),
    );
    final manager = SectionManager(runtime);
    final curve = await manager.create(
      planeId: '${WorldCoordinateSystem.prefix('project')}xy-plane',
      origin: Vector3.zero,
      normal: const Vector3(0, 0, 1),
    );

    expect(curve.id, 'ReferenceCurve001');
    expect(curve.data['referenceCurve'], isTrue);
    expect(curve.data['section']['meshId'], 'Mesh001');
    expect(curve.data['section']['segmentCount'], greaterThan(0));
    expect(FeatureLifecycleContract.require(curve).featureId, curve.id);
    final second = await manager.create(
      planeId: '${WorldCoordinateSystem.prefix('project')}yz-plane',
      origin: Vector3.zero,
      normal: const Vector3(1, 0, 0),
    );
    expect(second.id, 'ReferenceCurve002');
    final unrelatedBefore = runtime.document!.entities['Mesh001']!.toJson();

    final updated = await manager.setOffset(curve.id, .25);
    expect(updated.id, curve.id);
    expect(updated.data['revision'], 2);
    expect(updated.data['section']['offset'], closeTo(.25, 1e-9));
    expect(runtime.document!.entities[second.id]!.data['revision'], 1);
    expect(runtime.document!.entities['Mesh001']!.toJson(), unrelatedBefore);

    await manager.setDisplayMode(curve.id, 'highlighted');
    expect(
      runtime.scene.find(curve.id)!.geometry['displayColor'],
      'referenceCurveHighlight',
    );
    await manager.setDisplayMode(curve.id, 'curveOnly');
    expect(runtime.scene.find('Mesh001')!.visible, isFalse);
    await manager.setDisplayMode(curve.id, 'curveAndMesh');
    expect(runtime.scene.find('Mesh001')!.visible, isTrue);
    final recalculated = await manager.recalculate(curve.id);
    expect(recalculated.id, curve.id);
    expect(recalculated.data['revision'], 3);
    await manager.visibility(curve.id, false);
    expect(runtime.scene.find(curve.id)!.visible, isFalse);
    await manager.visibility(curve.id, true);
    expect(runtime.scene.find(curve.id)!.visible, isTrue);

    await runtime.save(recordLifecycle: true);
    await runtime.close();
    await runtime.open('project', directory);
    final restored = runtime.document!.entities['ReferenceCurve001']!;
    expect(restored.data['section']['offset'], closeTo(.25, 1e-9));
    expect(restored.data['section']['planeId'], contains('xy-plane'));
    expect(restored.data['section']['meshId'], 'Mesh001');
    expect(FeatureLifecycleContract.require(restored).featureId, curve.id);
    await runtime.transitionFeature(
      curve.id,
      FeatureLifecycleState.editing,
      command: 'feature.reenter',
    );
    expect(
      FeatureLifecycleContract.require(
        runtime.document!.entities[curve.id]!,
      ).state,
      FeatureLifecycleState.editing,
    );
  });
}
