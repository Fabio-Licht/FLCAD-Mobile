import 'dart:io';
import 'package:flcad_mobile/core/cad_builder/api/cad_builder_api.dart';
import 'package:flcad_mobile/core/cad_builder/commands/fel_cad_builder_commands.dart';
import 'package:flcad_mobile/core/cad_builder/engine/cad_builder_engine.dart';
import 'package:flcad_mobile/core/cad_builder/integration/cad_studio_integration.dart';
import 'package:flcad_mobile/core/cad_builder/repository/cad_builder_repository.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/engineering_studio/tree/engineering_tree_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late CadBuilderApi api;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_cad_builder_');
    api = CadBuilderApi(
      CadBuilderEngine(
        projectId: 'project',
        kernel: _BuilderKernel(),
        repository: CadBuilderRepository(root),
      ),
    );
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('builds and validates complete Vertex to Solid topology', () async {
    final v1 = (await api.vertex.point(0, 0, 0)).entity!.handle;
    final v2 = (await api.vertex.point(1, 0, 0)).entity!.handle;
    final edge = (await api.edge.line(v1, v2)).entity!.handle;
    final wire = (await api.wire.build([edge], closed: true)).entity!.handle;
    final face = (await api.face.planar(wire)).entity!.handle;
    final shell = (await api.shell.sew([face])).entity!.handle;
    final solid = await api.solid.fromClosedShell(shell);
    expect(solid.success, isTrue);
    expect(api.engine.graph.nodes, hasLength(7));
    expect(api.engine.graph.edges, hasLength(6));
    expect(api.engine.runtime.analytics.operations, 7);
  });

  test('refuses solid from an open shell without calling kernel', () async {
    final shell = ShapeHandle.reference(
      persistentId: 'open',
      kernelId: 'builder',
      type: CADShapeType.shell,
      metadata: const {'closed': false},
    );
    final result = await api.solid.fromClosedShell(shell);
    expect(result.success, isFalse);
    expect(result.diagnostics.single.code, 'shell-not-closed');
  });

  test('persists shapes and topology under Project CAD directories', () async {
    final result = await api.vertex.point(1, 2, 3);
    final repository = CadBuilderRepository(root);
    expect((await repository.loadAll()).single.handle, result.entity!.handle);
    expect(
      await Directory(
        '${root.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}Shapes',
      ).exists(),
      isTrue,
    );
    expect(
      await File(
        '${root.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}Topology${Platform.pathSeparator}geometry_graph.json',
      ).exists(),
      isTrue,
    );
  });

  test('history supports audit and undo removes persisted shape', () async {
    final entity = (await api.vertex.point(0, 0, 0)).entity!;
    expect(api.engine.history.entries, hasLength(1));
    expect(await api.engine.undo(), entity);
    expect(await api.engine.repository.loadAll(), isEmpty);
    expect(api.engine.history.entries.last.action.name, 'undo');
  });

  test(
    'Studio tree and property inspector expose CAD identity and validity',
    () async {
      final entity = (await api.vertex.point(0, 0, 0)).entity!;
      final tree = EngineeringTreeManager();
      const CadStudioIntegration().add(tree, entity);
      final sections = const PropertyInspector().inspect(tree.nodes.single);
      expect(tree.nodes.single.type.name, 'vertex');
      expect(
        sections
            .expand((e) => e.values.entries)
            .any(
              (e) =>
                  e.key == 'persistentId' &&
                  e.value == entity.handle.persistentId,
            ),
        isTrue,
      );
      expect(
        sections
            .expand((e) => e.values.entries)
            .any((e) => e.key == 'valid' && e.value == true),
        isTrue,
      );
    },
  );

  test('FEL exposes complete CAD Builder vocabulary', () {
    final names = createCadBuilderFELCommands().map((e) => e.name);
    expect(
      names,
      containsAll([
        'CREATE VERTEX',
        'CREATE EDGE',
        'CREATE WIRE',
        'CREATE FACE',
        'CREATE SHELL',
        'CREATE SOLID',
        'SHOW TOPOLOGY',
        'VALIDATE SHAPE',
        'SHOW SHAPE',
        'DELETE SHAPE',
      ]),
    );
  });
}

class _BuilderKernel implements GeometryKernelAPI {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'builder',
    name: 'Builder test contract',
    version: '1',
    capabilities: KernelCapabilities({KernelCapability.healing}),
    vendor: 'test',
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
    kernelId: 'builder',
    type: expectedType,
    fingerprint: 'fp-$persistentId',
    metadata: {
      'closed': expectedType == CADShapeType.wire
          ? parameters['closed'] == true
          : expectedType == CADShapeType.shell ||
                expectedType == CADShapeType.solid,
    },
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
