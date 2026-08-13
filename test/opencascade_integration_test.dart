import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/commands/fel_kernel_commands.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_bridge.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_plugin.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_runtime_repository.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_studio_integration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'plugin registers, initializes and unloads through KernelManager',
    () async {
      final bridge = _RecordingBridge();
      final manager = KernelManager();
      OpenCascadeKernelPlugin(bridge: bridge).register(manager);
      final health = await manager.select('opencascade');
      expect(health.status, KernelHealthStatus.healthy);
      expect(manager.active.descriptor.version, '7.8.1');
      expect(
        manager.active.descriptor.capabilities.values,
        containsAll([KernelCapability.step, KernelCapability.planeSurface]),
      );
      await manager.unload('opencascade');
      expect(bridge.shutdownCalled, isTrue);
    },
  );

  test(
    'unavailable native host fails explicitly and preserves fallback',
    () async {
      final manager = KernelManager();
      OpenCascadeKernelPlugin().register(manager);
      await expectLater(manager.select('opencascade'), throwsStateError);
      expect(manager.active.descriptor.id, 'none');
    },
  );

  test(
    'STEP and IGES import return opaque handles with no native token',
    () async {
      final bridge = _RecordingBridge();
      final adapter = OpenCascadeKernelAdapter(bridge: bridge);
      await adapter.initialize();
      final step = await adapter.importFile(
        'part.step',
        KernelExchangeFormat.step,
        projectId: 'project',
      );
      final iges = await adapter.importFile(
        'part.igs',
        KernelExchangeFormat.iges,
        projectId: 'project',
      );
      expect([step.type, iges.type], [CADShapeType.solid, CADShapeType.solid]);
      expect(step.fingerprint, 'sha256:test');
      expect(step.toJson().toString(), isNot(contains('TopoDS')));
      expect(bridge.imports, ['step:part.step', 'iges:part.igs']);
    },
  );

  test(
    'export validation healing sewing and meshing route only through bridge',
    () async {
      final bridge = _RecordingBridge();
      final adapter = OpenCascadeKernelAdapter(bridge: bridge);
      await adapter.initialize();
      final handle = await adapter.importFile(
        'part.brep',
        KernelExchangeFormat.brep,
        projectId: 'p',
      );
      await adapter.exportFile(handle, 'out.step', KernelExchangeFormat.step);
      expect(await adapter.diagnose(handle), hasLength(1));
      expect(await adapter.proposeHealing(handle), hasLength(1));
      final shell = await adapter.sew(
        [handle],
        projectId: 'p',
        tolerance: 0.01,
      );
      expect(shell.type, CADShapeType.shell);
      final mesh = await adapter.mesh(
        handle,
        outputPath: 'mesh.bin',
        deflection: 0.1,
      );
      expect([mesh.vertexCount, mesh.triangleCount], [3, 1]);
      expect(bridge.exports, ['step:out.step']);
      expect(adapter.runtime.analytics.operations, 6);
    },
  );

  test('FEL registers real OCC command surface', () {
    final names = createKernelFELCommands().map((e) => e.name);
    expect(
      names,
      containsAll([
        'IMPORT STEP',
        'IMPORT IGES',
        'EXPORT STEP',
        'EXPORT IGES',
        'VALIDATE GEOMETRY',
        'HEAL GEOMETRY',
        'SHOW KERNEL VERSION',
        'SHOW KERNEL STATUS',
        'CREATE PLANE',
        'CREATE CYLINDER',
        'VALIDATE SHAPE',
        'HEAL SHAPE',
      ]),
    );
  });

  test('FFI loader reports a missing native library without fabrication', () {
    expect(OpenCascadeFFI.tryLoad(path: 'definitely-missing-occt.dll'), isNull);
  });

  test('native metadata repository creates project-first structure', () async {
    final root = await Directory.systemTemp.createTemp('flcad-occ-');
    addTearDown(() => root.delete(recursive: true));
    const repository = OpenCascadeRuntimeRepository();
    final handle = ShapeHandle.reference(
      persistentId: 'shape-1',
      kernelId: 'opencascade',
      type: CADShapeType.face,
      metadata: {'topoDSType': 'face'},
    );
    final file = await repository.saveShapeMetadata(root, handle);
    expect(await file.exists(), isTrue);
    for (final folder in const [
      'Kernel',
      'KernelCache',
      'KernelDiagnostics',
      'NativeShapes',
    ]) {
      expect(
        await Directory(
          '${root.path}${Platform.pathSeparator}$folder',
        ).exists(),
        isTrue,
      );
    }
  });

  test('Studio exposes kernel status and portable inspector context', () async {
    final manager = KernelManager();
    OpenCascadeKernelPlugin(bridge: _RecordingBridge()).register(manager);
    await manager.select('opencascade');
    final snapshot = await const OpenCascadeStudioIntegration().inspect(
      manager,
    );
    final node = snapshot.toTreeNode('project');
    expect(node.context['kernelId'], 'opencascade');
    expect(node.context['kernelVersion'], '7.8.1');
    expect(node.context.toString(), isNot(contains('TopoDS_Shape')));
  });
}

class _RecordingBridge implements OpenCascadeNativeBridge {
  final imports = <String>[];
  final exports = <String>[];
  bool shutdownCalled = false;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> shutdown() async => shutdownCalled = true;
  @override
  Future<String> version() async => '7.8.1';
  @override
  Future<Set<String>> capabilities() async => {
    'STEP',
    'IGES',
    'BREP',
    'Surface',
    'Meshing',
    'Healing',
  };
  @override
  Future<Map<String, dynamic>> diagnostics() async => {'healthy': true};
  @override
  Future<OpenCascadeNativeShape> createShape(
    String operation,
    Map<String, dynamic> parameters,
    CADShapeType expectedType,
  ) async => OpenCascadeNativeShape(
    token: 'created-${expectedType.name}',
    type: expectedType,
    fingerprint: 'sha256:${expectedType.name}',
  );
  @override
  Future<OpenCascadeNativeShape> importShape(
    String path,
    KernelExchangeFormat format, {
    required KernelCancellationToken cancellation,
    void Function(KernelProgress progress)? onProgress,
  }) async {
    imports.add('${format.name}:$path');
    return const OpenCascadeNativeShape(
      token: 'TopoDS-private-token',
      type: CADShapeType.solid,
      fingerprint: 'sha256:test',
      metadata: {'source': 'native'},
    );
  }

  @override
  Future<void> exportShape(
    String nativeToken,
    String path,
    KernelExchangeFormat format, {
    required KernelCancellationToken cancellation,
    void Function(KernelProgress progress)? onProgress,
  }) async {
    expect(nativeToken, 'TopoDS-private-token');
    exports.add('${format.name}:$path');
  }

  @override
  Future<List<GeometryDiagnostic>> validate(String nativeToken) async => const [
    GeometryDiagnostic(
      code: 'open-shell',
      message: 'Shell is open',
      severity: 'warning',
    ),
  ];
  @override
  Future<List<HealingProposal>> proposeHealing(String nativeToken) async =>
      const [
        HealingProposal(
          id: 'h1',
          operation: 'fix-shape',
          reason: 'Open shell',
          diagnostics: [],
        ),
      ];
  @override
  Future<OpenCascadeNativeShape> sew(
    List<String> nativeTokens,
    double tolerance,
  ) async => const OpenCascadeNativeShape(
    token: 'shell-token',
    type: CADShapeType.shell,
    fingerprint: 'sha256:shell',
  );
  @override
  Future<KernelMeshData> mesh(
    String nativeToken,
    String outputPath,
    double deflection,
  ) async => KernelMeshData(3, 1, outputPath);
}
