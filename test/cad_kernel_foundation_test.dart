import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/analytics/kernel_analytics.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/factories/geometry_factories.dart';
import 'package:flcad_mobile/core/cad_kernel/graph/geometry_graph.dart';
import 'package:flcad_mobile/core/cad_kernel/history/geometry_history.dart';
import 'package:flcad_mobile/core/cad_kernel/ids/persistent_id_service.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/cad_kernel/plugins/kernel_plugin.dart';
import 'package:flcad_mobile/core/cad_kernel/runtime/kernel_runtime.dart';
import 'package:flcad_mobile/core/cad_kernel/transactions/kernel_transaction_manager.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'kernel manager registers selects checks capabilities falls back and unloads',
    () async {
      final manager = KernelManager()..register(_Kernel());
      final health = await manager.select('test');
      expect(health.status, KernelHealthStatus.healthy);
      expect(
        manager.active.descriptor.capabilities.supports(
          KernelCapability.meshing,
        ),
        isTrue,
      );
      await manager.unload('test');
      expect(manager.active.descriptor.id, 'none');
    },
  );
  test(
    'shape handle is opaque serializable and based on persistent identity',
    () {
      const ids = PersistentIdService();
      final id = ids.create('p', 'face'),
          handle = ShapeHandle.reference(
            persistentId: id,
            kernelId: 'test',
            type: CADShapeType.face,
          );
      expect(ids.valid(id), isTrue);
      expect(ShapeHandle.fromJson(handle.toJson()), handle);
      expect(
        () => ShapeHandle.reference(
          persistentId: '',
          kernelId: 'k',
          type: CADShapeType.edge,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'factories delegate to plugin and unavailable factory refuses geometry',
    () async {
      final kernel = _Kernel(),
          tx = KernelTransaction(
            't',
            'p',
            'test',
            DateTime.now(),
            TransactionStatus.active,
            const [],
          );
      final handle = await GeometryFactories(
        kernel,
      ).vertex.create(const {'x': 0}, projectId: 'p', transaction: tx);
      expect(handle.type, CADShapeType.vertex);
      expect(
        () => GeometryFactories(
          const UnavailableGeometryKernel(),
        ).solid.create(const {}, projectId: 'p', transaction: tx),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );
  test(
    'transactions begin commit rollback and reject closed mutation',
    () async {
      final manager = KernelTransactionManager(_Kernel()),
          first = await manager.begin('p');
      final withOperation = manager.addOperation(first.id, 'op');
      expect(withOperation.operationIds, ['op']);
      final committed = await manager.commit(first.id);
      expect(committed.status, TransactionStatus.committed);
      expect(() => manager.rollback(first.id), throwsStateError);
      final second = await manager.begin('p');
      expect(
        (await manager.rollback(second.id)).status,
        TransactionStatus.rolledBack,
      );
    },
  );
  test(
    'geometry graph enforces topology hierarchy and history remains project scoped',
    () {
      ShapeHandle h(String id, CADShapeType type) => ShapeHandle.reference(
        persistentId: 'p:$id:1',
        kernelId: 'k',
        type: type,
      );
      final graph = GeometryGraph();
      graph.add(GeometryGraphNode(h('v', CADShapeType.vertex), const {}));
      graph.add(GeometryGraphNode(h('e', CADShapeType.edge), const {}));
      graph.connect(const GeometryGraphEdge('p:v:1', 'p:e:1', 'bounds'));
      expect(
        () =>
            graph.connect(const GeometryGraphEdge('p:e:1', 'p:v:1', 'invalid')),
        throwsStateError,
      );
      final history = GeometryHistory()
        ..record(
          projectId: 'p',
          action: GeometryHistoryAction.create,
          shapes: [h('v', CADShapeType.vertex)],
          transactionId: 't',
          actor: 'test',
        );
      expect(history.forProject('p'), hasLength(1));
    },
  );
  test(
    'plugins validate compatibility and runtime records analytics',
    () async {
      final registry = KernelPluginRegistry()..register(_Plugin());
      expect(() => registry.register(_Plugin()), throwsStateError);
      final analytics = KernelAnalytics(),
          runtime = KernelRuntime(analytics: analytics);
      expect(
        await runtime.run('kernel-test', () async => 7, entityCount: 2),
        7,
      );
      expect(analytics.operations, 1);
      expect(analytics.entities, 2);
    },
  );
  test('FEL exposes complete kernel foundation vocabulary', () {
    final names = createNativeCommandRegistry(Directory.systemTemp).names;
    for (final name in [
      'LOAD KERNEL',
      'UNLOAD KERNEL',
      'SHOW KERNEL',
      'SHOW CAPABILITIES',
      'SHOW TOPOLOGY',
      'SHOW GEOMETRY GRAPH',
      'VALIDATE GEOMETRY',
      'BEGIN TRANSACTION',
      'COMMIT TRANSACTION',
      'ROLLBACK TRANSACTION',
    ]) {
      expect(names, contains(name));
    }
  });
}

class _Plugin implements KernelPlugin {
  @override
  String get pluginId => 'test-plugin';
  @override
  String get pluginVersion => '1';
  @override
  bool get compatible => true;
  @override
  GeometryKernelAPI createKernel() => _Kernel();
}

class _Kernel implements GeometryKernelAPI {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'test',
    name: 'Test Contract Kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({KernelCapability.meshing}),
  );
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
  }) async => ShapeHandle.reference(
    persistentId: persistentId,
    kernelId: 'test',
    type: expectedType,
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
}
