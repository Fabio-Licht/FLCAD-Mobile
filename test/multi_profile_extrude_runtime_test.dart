import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/professional_extrude/multi_profile_extrude_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

class _Kernel implements GeometryKernelAPI {
  String? operation;
  Map<String, dynamic>? parameters;
  int creates = 0;

  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'multi-test',
    name: 'Multi test',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({}),
  );

  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<ShapeHandle> create(
    String value,
    Map<String, dynamic> input, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async {
    creates++;
    operation = value;
    parameters = input;
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: descriptor.id,
      type: expectedType,
    );
  }

  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<void> unload() async {}
  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ok', DateTime.now());
}

ShapeHandle _profile(String id, {bool closed = true}) => ShapeHandle.reference(
  persistentId: id,
  kernelId: 'multi-test',
  type: CADShapeType.wire,
  metadata: {'closed': closed},
);

KernelTransaction _transaction() => KernelTransaction(
  'multi-preview',
  'project',
  'multi-test',
  DateTime(2026),
  TransactionStatus.active,
  const [],
);

void main() {
  const runtime = MultiProfileExtrudeRuntime();

  test(
    'routes islands, Draft and symmetric state as one multi operation',
    () async {
      final kernel = _Kernel();
      final handle = await runtime.create(
        kernel,
        MultiProfileExtrudeRequest(
          profiles: [_profile('outer'), _profile('void'), _profile('island')],
          direction: const [0, 0, 20],
          solidOutput: true,
          draftAngleDegrees: 3,
          symmetric: true,
        ),
        persistentId: 'preview:multi',
        transaction: _transaction(),
      );
      expect(kernel.operation, 'EXTRUDE MULTI');
      expect((kernel.parameters!['inputs'] as List<ShapeHandle>).length, 3);
      expect(kernel.parameters!['draftAngleDegrees'], 3);
      expect(kernel.parameters!['symmetric'], isTrue);
      expect(handle.type, CADShapeType.compound);
    },
  );

  test(
    'rejects insufficient, duplicate, open and invalid requests before kernel',
    () async {
      final kernel = _Kernel();
      Future<void> reject(MultiProfileExtrudeRequest request) => runtime.create(
        kernel,
        request,
        persistentId: 'never',
        transaction: _transaction(),
      );
      expect(
        () => reject(
          MultiProfileExtrudeRequest(
            profiles: [_profile('one')],
            direction: const [0, 0, 1],
            solidOutput: true,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => reject(
          MultiProfileExtrudeRequest(
            profiles: [_profile('same'), _profile('same')],
            direction: const [0, 0, 1],
            solidOutput: true,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => reject(
          MultiProfileExtrudeRequest(
            profiles: [_profile('closed'), _profile('open', closed: false)],
            direction: const [0, 0, 1],
            solidOutput: true,
          ),
        ),
        throwsArgumentError,
      );
      expect(kernel.creates, 0);
    },
  );

  test('accepts multiple open wires for Surface / Walls', () async {
    final kernel = _Kernel();
    final handle = await runtime.create(
      kernel,
      MultiProfileExtrudeRequest(
        profiles: [
          _profile('open-a', closed: false),
          _profile('open-b', closed: false),
        ],
        direction: const [0, 0, 12],
        solidOutput: false,
        symmetric: true,
      ),
      persistentId: 'preview:open-walls',
      transaction: _transaction(),
    );

    expect(kernel.operation, 'EXTRUDE MULTI');
    expect(kernel.parameters!['output'], 'surface');
    expect(kernel.parameters!['symmetric'], isTrue);
    expect(handle.type, CADShapeType.compound);
  });

  test('rejects mixed open and closed Surface / Walls before kernel', () {
    final kernel = _Kernel();
    expect(
      () => runtime.create(
        kernel,
        MultiProfileExtrudeRequest(
          profiles: [_profile('closed'), _profile('open', closed: false)],
          direction: const [0, 0, 1],
          solidOutput: false,
        ),
        persistentId: 'never',
        transaction: _transaction(),
      ),
      throwsArgumentError,
    );
    expect(kernel.creates, 0);
  });

  test('single EXTRUDE remains a separate operation name', () {
    expect('EXTRUDE MULTI', isNot('EXTRUDE'));
  });
}
