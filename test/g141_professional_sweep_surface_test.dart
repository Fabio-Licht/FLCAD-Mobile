import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/professional_surface/api/professional_surface_modeling_api.dart';
import 'package:flcad_mobile/core/professional_surface/models/professional_surface_models.dart';
import 'package:flcad_mobile/core/professional_surface/repository/professional_surface_repository.dart';
import 'package:flcad_mobile/core/professional_sweep/professional_sweep.dart';
import 'package:flcad_mobile/core/surface_generation/api/surface_generation_api.dart';
import 'package:flcad_mobile/core/surface_operations/api/surface_operations_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = SweepConstraintAdapter();

  test('accepts only the three authorized profile and path combinations', () {
    final valid = [
      (SweepInputKind.sketch, SweepInputKind.sketch),
      (SweepInputKind.sketch, SweepInputKind.referenceCurve),
      (SweepInputKind.edge, SweepInputKind.edge),
    ];
    for (final combination in valid) {
      final profile = _input('Profile', combination.$1, 1, 'profile-wire');
      final path = _input('Path', combination.$2, 1, 'path-wire');
      final plan = adapter.solve(profile: profile, path: path);
      expect(plan.anchor, 'Profile');
      expect(plan.moving, 'Path');
      expect(adapter.health(profile: profile, path: path).ready, isTrue);
    }
    expect(
      () => adapter.solve(
        profile: _input(
          'Profile',
          SweepInputKind.referenceCurve,
          1,
          'profile-wire',
        ),
        path: _input('Path', SweepInputKind.sketch, 1, 'path-wire'),
      ),
      throwsArgumentError,
    );
  });

  test('preview is transient and confirmation persists Sweep001', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g141-');
    addTearDown(() => directory.delete(recursive: true));
    final kernel = _SweepKernel();
    final repository = ProfessionalSurfaceRepository(directory);
    final api = _api(kernel, repository);
    final profile = _input(
      'Sketch001',
      SweepInputKind.sketch,
      2,
      'profile-wire',
    );
    final path = _input(
      'ReferenceCurve001',
      SweepInputKind.referenceCurve,
      5,
      'path-wire',
    );
    final health = adapter.health(profile: profile, path: path);
    final draft = api.begin(
      tool: ProfessionalSurfaceTool.sweep,
      featureId: 'Sweep001',
      name: 'Sweep001',
      references: [profile.shapeId, path.shapeId],
      parameters: {
        'sourceEntityIds': [profile.entityId, path.entityId],
        'profile': profile.toJson(),
        'path': path.toJson(),
        'health': health.toJson(),
        'solverContract': 'flcad.geometry-constraint-solver/v1',
        'multiplePaths': false,
        'guideCurves': const <String>[],
        'twist': false,
        'scaling': false,
      },
      continuity: SurfaceContinuity.g0,
    );
    final preview = await api.preview(draft.definition.id);
    expect(preview.transparent, isTrue);
    expect(preview.definition.id, 'Sweep001');
    expect(await _api(kernel, repository).load(), isEmpty);

    final committed = await api.confirm('Sweep001');
    expect(committed.status, SurfaceFeatureStatus.committed);
    expect(committed.id, 'Sweep001');
    expect(committed.parameters['profile']['entityId'], 'Sketch001');
    expect(committed.parameters['path']['entityId'], 'ReferenceCurve001');
    expect(kernel.operations, everyElement('CREATE SURFACE SWEEP'));

    final restored = (await _api(kernel, repository).load()).single;
    expect(restored.id, 'Sweep001');
    expect(restored.references, ['profile-wire', 'path-wire']);
    expect(restored.parameters['twist'], isFalse);
    expect(restored.parameters['scaling'], isFalse);
  });

  test('parametric path update preserves Sweep identity and history', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g141-');
    addTearDown(() => directory.delete(recursive: true));
    final kernel = _SweepKernel();
    final repository = ProfessionalSurfaceRepository(directory);
    final api = _api(kernel, repository);
    final profile = _input('Edge001', SweepInputKind.edge, 1, 'edge-profile');
    final path = _input('Edge002', SweepInputKind.edge, 1, 'edge-path-r1');
    final draft = api.begin(
      tool: ProfessionalSurfaceTool.sweep,
      featureId: 'Sweep001',
      references: [profile.shapeId, path.shapeId],
      parameters: {'profile': profile.toJson(), 'path': path.toJson()},
    );
    await api.preview(draft.definition.id);
    final created = await api.confirm(draft.definition.id);
    final updatedPath = _input(
      'Edge002',
      SweepInputKind.edge,
      2,
      'edge-path-r2',
    );
    final updated = await api.edit(
      created.id,
      references: [profile.shapeId, updatedPath.shapeId],
      parameters: {'profile': profile.toJson(), 'path': updatedPath.toJson()},
      continuity: SurfaceContinuity.g0,
    );
    expect(updated.id, created.id);
    expect(updated.revision, greaterThan(created.revision));
    expect(updated.parameters['path']['revision'], 2);
    expect(api.surfaces.where((item) => item.id == 'Sweep001').length, 1);
  });

  test('professional Sweep naming never duplicates identity', () {
    expect(ProfessionalSweepNaming.nextId(const []), 'Sweep001');
    expect(
      ProfessionalSweepNaming.nextId(const ['Sweep001', 'Sweep003']),
      'Sweep002',
    );
  });
}

SweepInputReference _input(
  String id,
  SweepInputKind kind,
  int revision,
  String shapeId,
) => SweepInputReference(
  entityId: id,
  kind: kind,
  revision: revision,
  shapeId: shapeId,
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

class _SweepKernel implements GeometryKernelAPI {
  final List<String> operations = [];

  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'test',
    name: 'Test',
    version: '1',
    vendor: 'FLCAD',
    capabilities: KernelCapabilities({KernelCapability.sweep}),
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
