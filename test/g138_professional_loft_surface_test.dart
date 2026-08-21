import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/professional_loft/professional_loft.dart';
import 'package:flcad_mobile/core/professional_surface/api/professional_surface_modeling_api.dart';
import 'package:flcad_mobile/core/professional_surface/models/professional_surface_models.dart';
import 'package:flcad_mobile/core/professional_surface/repository/professional_surface_repository.dart';
import 'package:flcad_mobile/core/surface_generation/api/surface_generation_api.dart';
import 'package:flcad_mobile/core/surface_operations/api/surface_operations_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = LoftConstraintAdapter();

  test('accepts exactly two homogeneous professional section types', () {
    for (final kind in LoftSectionKind.values) {
      final sections = [_section('A', kind, 1), _section('B', kind, 1)];
      final plan = adapter.solve(sections);
      expect(plan.anchor, 'A');
      expect(plan.moving, 'B');
      expect(adapter.health(sections).toJson(), {
        'valid': true,
        'topologyOk': true,
        'boundariesOk': true,
        'ready': true,
        'message': 'Loft is ready.',
      });
    }
    expect(
      () => adapter.solve([
        _section('A', LoftSectionKind.sketch, 1),
        _section('B', LoftSectionKind.edge, 1),
      ]),
      throwsArgumentError,
    );
  });

  test('preview is transient and confirmation persists Loft001', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g138-');
    addTearDown(() => directory.delete(recursive: true));
    final kernel = _LoftKernel();
    final repository = ProfessionalSurfaceRepository(directory);
    final api = _api(kernel, repository);
    final sections = [
      _section('Sketch001', LoftSectionKind.sketch, 3),
      _section('Sketch002', LoftSectionKind.sketch, 4),
    ];
    final health = adapter.health(sections);
    final draft = api.begin(
      tool: ProfessionalSurfaceTool.loft,
      featureId: 'Loft001',
      name: 'Loft001',
      references: sections.map((item) => item.shapeId).toList(),
      parameters: {
        'sourceEntityIds': sections.map((item) => item.entityId).toList(),
        'sections': sections.map((item) => item.toJson()).toList(),
        'health': health.toJson(),
        'solverContract': 'flcad.geometry-constraint-solver/v1',
      },
      continuity: SurfaceContinuity.g0,
    );
    final preview = await api.preview(draft.definition.id);
    expect(preview.transparent, isTrue);
    expect(preview.definition.id, 'Loft001');
    expect(await _api(kernel, repository).load(), isEmpty);

    final committed = await api.confirm('Loft001');
    expect(committed.status, SurfaceFeatureStatus.committed);
    expect(committed.id, 'Loft001');
    expect(committed.continuity, SurfaceContinuity.g0);
    expect(kernel.operations, everyElement('CREATE SURFACE LOFT'));

    final reopened = _api(kernel, repository);
    final restored = (await reopened.load()).single;
    expect(restored.id, 'Loft001');
    expect(restored.references, ['wire-A', 'wire-B']);
    expect(restored.parameters['sourceEntityIds'], ['Sketch001', 'Sketch002']);
  });

  test(
    'parametric edit keeps identity and advances history revision',
    () async {
      final directory = await Directory.systemTemp.createTemp('flcad-g138-');
      addTearDown(() => directory.delete(recursive: true));
      final kernel = _LoftKernel();
      final repository = ProfessionalSurfaceRepository(directory);
      final api = _api(kernel, repository);
      final draft = api.begin(
        tool: ProfessionalSurfaceTool.loft,
        featureId: 'Loft001',
        references: const ['edge-A-r1', 'edge-B-r1'],
        parameters: const {
          'sourceEntityIds': ['Edge001', 'Edge002'],
        },
      );
      await api.preview(draft.definition.id);
      final created = await api.confirm(draft.definition.id);
      final updated = await api.edit(
        created.id,
        references: const ['edge-A-r2', 'edge-B-r1'],
        parameters: const {
          'sourceEntityIds': ['Edge001', 'Edge002'],
        },
        continuity: SurfaceContinuity.g0,
      );
      expect(updated.id, created.id);
      expect(updated.revision, greaterThan(created.revision));
      expect(updated.references.first, 'edge-A-r2');
      expect(api.surfaces.where((item) => item.id == 'Loft001').length, 1);
    },
  );

  test('professional naming never duplicates a persisted Loft identity', () {
    expect(ProfessionalLoftNaming.nextId(const []), 'Loft001');
    expect(
      ProfessionalLoftNaming.nextId(const ['Loft001', 'Loft003']),
      'Loft002',
    );
  });
}

LoftSectionReference _section(String id, LoftSectionKind kind, int revision) =>
    LoftSectionReference(
      entityId: id,
      kind: kind,
      revision: revision,
      shapeId: id == 'A'
          ? 'wire-A'
          : id == 'B'
          ? 'wire-B'
          : id.endsWith('001')
          ? 'wire-A'
          : 'wire-B',
    );

ProfessionalSurfaceModelingApi _api(
  GeometryKernelAPI kernel,
  ProfessionalSurfaceRepository repository,
) => ProfessionalSurfaceModelingApi(
  projectId: 'project',
  kernel: kernel,
  generation: _GenerationApi(),
  operations: _OperationsApi(),
  repository: repository,
);

class _GenerationApi implements SurfaceGenerationApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OperationsApi implements SurfaceOperationsApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoftKernel implements GeometryKernelAPI {
  final List<String> operations = [];

  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'test',
    name: 'Test',
    version: '1',
    vendor: 'FLCAD',
    capabilities: KernelCapabilities({KernelCapability.loft}),
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
}
