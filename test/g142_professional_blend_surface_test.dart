import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/professional_blend/professional_blend.dart';
import 'package:flcad_mobile/core/professional_surface/api/professional_surface_modeling_api.dart';
import 'package:flcad_mobile/core/professional_surface/models/professional_surface_models.dart';
import 'package:flcad_mobile/core/professional_surface/repository/professional_surface_repository.dart';
import 'package:flcad_mobile/core/surface_generation/api/surface_generation_api.dart';
import 'package:flcad_mobile/core/surface_operations/api/surface_operations_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = BlendConstraintAdapter();

  test('Blend requires paired boundaries and independent G0/G1', () {
    final first = _surface(
      'Surface001',
      'face-a',
      edge: 'Edge001',
      continuity: BlendContinuity.g1,
    );
    final second = _surface(
      'Surface002',
      'face-b',
      edge: 'Edge002',
      continuity: BlendContinuity.g1,
    );
    expect(
      adapter
          .health(first: first, second: second, continuity: BlendContinuity.g0)
          .ready,
      isTrue,
    );
    expect(
      adapter
          .health(first: first, second: second, continuity: BlendContinuity.g1)
          .quality,
      1,
    );
    final edgeFirst = _surface(
      'Surface001',
      'face-a',
      edge: 'Edge001',
      continuity: BlendContinuity.g1,
      influence: .35,
    );
    final edgeSecond = _surface(
      'Surface002',
      'face-b',
      edge: 'Edge002',
      continuity: BlendContinuity.g0,
    );
    expect(
      adapter
          .health(
            first: edgeFirst,
            second: edgeSecond,
            continuity: BlendContinuity.g1,
          )
          .boundaries,
      isTrue,
    );
    expect(BlendSurfaceReference.fromJson(edgeFirst.toJson()).influence, .35);
    expect(
      () => adapter.solve(
        first: edgeFirst,
        second: _surface('Surface002', 'face-b'),
        continuity: BlendContinuity.g0,
      ),
      throwsArgumentError,
    );
    expect(
      () => adapter.solve(
        first: first,
        second: second,
        continuity: BlendContinuity.g2Prepared,
      ),
      throwsUnsupportedError,
    );
  });

  test(
    'preview is transient and confirmation persists independent Blend001',
    () async {
      final directory = await Directory.systemTemp.createTemp('flcad-g142-');
      addTearDown(() => directory.delete(recursive: true));
      final kernel = _BlendKernel();
      final repository = ProfessionalSurfaceRepository(directory);
      final api = _api(kernel, repository);
      final first = _surface('Surface001', 'face-a', edge: 'Edge001');
      final second = _surface('Surface002', 'face-b', edge: 'Edge002');
      final handles = [
        _handle('face-a'),
        _handle('face-b'),
        _handle('edge-a'),
        _handle('edge-b'),
      ];
      final draft = api.begin(
        tool: ProfessionalSurfaceTool.blend,
        featureId: 'Blend001',
        name: 'Blend001',
        references: handles.map((e) => e.persistentId).toList(),
        parameters: {
          'shapeHandles': handles.map((e) => e.toJson()).toList(),
          'sourceEntityIds': ['Surface001', 'Surface002'],
          'participants': [first.toJson(), second.toJson()],
          'health': adapter
              .health(
                first: first,
                second: second,
                continuity: BlendContinuity.g1,
              )
              .toJson(),
          'g2Supported': false,
        },
        continuity: SurfaceContinuity.g1,
      );
      final preview = await api.preview(draft.definition.id);
      expect(preview.transparent, isTrue);
      expect(await _api(kernel, repository).load(), isEmpty);
      final committed = await api.confirm('Blend001');
      expect(committed.id, 'Blend001');
      expect(committed.continuity, SurfaceContinuity.g1);
      expect(committed.parameters['sourceEntityIds'], [
        'Surface001',
        'Surface002',
      ]);
      expect(kernel.operations, everyElement('CREATE SURFACE BLEND'));
      expect(
        kernel.sourceWasInjected,
        isFalse,
        reason: 'Blend must not edit either source Surface',
      );
      expect((await _api(kernel, repository).load()).single.id, 'Blend001');
    },
  );

  test('participant update preserves Blend identity and history', () async {
    final directory = await Directory.systemTemp.createTemp('flcad-g142-');
    addTearDown(() => directory.delete(recursive: true));
    final kernel = _BlendKernel();
    final api = _api(kernel, ProfessionalSurfaceRepository(directory));
    final first = _surface('Surface001', 'face-a');
    final second = _surface('Surface002', 'face-b');
    api.begin(
      tool: ProfessionalSurfaceTool.blend,
      featureId: 'Blend001',
      references: ['face-a', 'face-b'],
      parameters: {
        'participants': [first.toJson(), second.toJson()],
      },
    );
    await api.preview('Blend001');
    final created = await api.confirm('Blend001');
    final changed = BlendSurfaceReference(
      entityId: 'Surface002',
      revision: 2,
      shapeId: 'face-b-r2',
    );
    final updated = await api.edit(
      created.id,
      references: ['face-a', 'face-b-r2'],
      parameters: {
        'participants': [first.toJson(), changed.toJson()],
      },
      continuity: SurfaceContinuity.g0,
    );
    expect(updated.id, created.id);
    expect(updated.revision, greaterThan(created.revision));
    expect(updated.parameters['participants'][1]['revision'], 2);
    expect(api.surfaces.where((item) => item.id == 'Blend001').length, 1);
  });

  test('Blend naming never duplicates identity', () {
    expect(ProfessionalBlendNaming.nextId(const []), 'Blend001');
    expect(
      ProfessionalBlendNaming.nextId(const ['Blend001', 'Blend003']),
      'Blend002',
    );
  });
}

BlendSurfaceReference _surface(
  String id,
  String shape, {
  String? edge,
  BlendContinuity continuity = BlendContinuity.g0,
  double influence = 1,
}) => BlendSurfaceReference(
  entityId: id,
  revision: 1,
  shapeId: shape,
  boundaryEntityId: edge,
  boundaryShapeId: edge == null
      ? null
      : 'edge-${id == 'Surface001' ? 'a' : 'b'}',
  continuity: continuity,
  influence: influence,
);
ShapeHandle _handle(String id) => ShapeHandle.reference(
  persistentId: id,
  kernelId: 'test',
  type: CADShapeType.face,
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

class _BlendKernel implements GeometryKernelAPI {
  final List<String> operations = [];
  bool sourceWasInjected = false;
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
    sourceWasInjected |= parameters.containsKey('source');
    return _handle(persistentId);
  }

  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
}
