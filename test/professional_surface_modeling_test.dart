import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/professional_surface/api/professional_surface_modeling_api.dart';
import 'package:flcad_mobile/core/professional_surface/models/professional_surface_models.dart';
import 'package:flcad_mobile/core/professional_surface/repository/professional_surface_repository.dart';
import 'package:flcad_mobile/core/surface_generation/api/surface_generation_api.dart';
import 'package:flcad_mobile/core/surface_operations/api/surface_operations_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loft supports preview, persistence, reload, undo and redo', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g103-');
    addTearDown(() => directory.delete(recursive: true));
    final kernel = _Kernel();
    final api = ProfessionalSurfaceModelingApi(
      projectId: 'project',
      kernel: kernel,
      generation: _GenerationApi(),
      operations: _OperationsApi(),
      repository: ProfessionalSurfaceRepository(directory),
    );

    final draft = api.loft(['section-a', 'section-b']);
    final preview = await api.preview(draft.definition.id);
    expect(preview.transparent, isTrue);

    final committed = await api.confirm(draft.definition.id);
    expect(committed.status, SurfaceFeatureStatus.committed);
    expect(await api.undo(), isTrue);
    expect(api.surfaces.where((item) => item.id == committed.id), isEmpty);
    expect(await api.redo(), isTrue);
    expect(api.surfaces.where((item) => item.id == committed.id), isNotEmpty);

    final restored = ProfessionalSurfaceModelingApi(
      projectId: 'project',
      kernel: kernel,
      generation: _GenerationApi(),
      operations: _OperationsApi(),
      repository: ProfessionalSurfaceRepository(directory),
    );
    expect((await restored.load()).single.references, [
      'section-a',
      'section-b',
    ]);
    expect(kernel.operations, contains('CREATE SURFACE LOFT'));
  });

  test('validates professional surface inputs', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g103-');
    addTearDown(() => directory.delete(recursive: true));
    final api = ProfessionalSurfaceModelingApi(
      projectId: 'project',
      kernel: _Kernel(),
      generation: _GenerationApi(),
      operations: _OperationsApi(),
      repository: ProfessionalSurfaceRepository(directory),
    );
    expect(() => api.loft(['only-one']), throwsArgumentError);
    expect(() => api.sweep(profile: 'profile', path: ''), throwsArgumentError);
    expect(
      api.buildTree().map((e) => e.label),
      containsAll([
        'Surface Groups',
        'Surface Sets',
        'Loft',
        'Sweep',
        'Blend',
        'Fill',
      ]),
    );
  });
}

class _GenerationApi implements SurfaceGenerationApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OperationsApi implements SurfaceOperationsApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Kernel implements GeometryKernelAPI, SurfaceQualityKernelAPI {
  final List<String> operations = [];
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'test',
    name: 'Test',
    version: '1',
    vendor: 'FLCAD',
    capabilities: KernelCapabilities({
      KernelCapability.loft,
      KernelCapability.sweep,
    }),
  );
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ok', DateTime.now());
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async {
    operations.add(operation);
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: 'test',
      type: expectedType,
    );
  }

  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<Map<String, dynamic>> inspectSurfaceQuality(
    ShapeHandle surface, {
    required List<double> draftDirection,
    int samples = 100,
  }) async => {'curvatureStability': 1.0, 'gaussianCurvature': 0.0};
}
