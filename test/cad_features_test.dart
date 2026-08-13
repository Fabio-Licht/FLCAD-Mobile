import 'dart:io';
import 'package:flcad_mobile/core/cad_features/api/feature_api.dart';
import 'package:flcad_mobile/core/cad_features/commands/fel_feature_commands.dart';
import 'package:flcad_mobile/core/cad_features/engine/feature_engine.dart';
import 'package:flcad_mobile/core/cad_features/integration/feature_studio_integration.dart';
import 'package:flcad_mobile/core/cad_features/models/feature_models.dart';
import 'package:flcad_mobile/core/cad_features/repository/feature_repository.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/engineering_studio/tree/engineering_tree_manager.dart';
import 'package:flcad_mobile/core/engineering/graph/engineering_graph.dart';
import 'package:flcad_mobile/core/engineering/history/engineering_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late FeatureApi api;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_features_');
    api = FeatureApi(
      FeatureEngine(
        projectId: 'p',
        kernel: _FeatureKernel(),
        repository: FeatureRepository(root),
      ),
    );
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  test(
    'feature engine builds Extrude Revolve Sweep and Loft through kernel',
    () async {
      final profile = _shape('profile', CADShapeType.face),
          axis = _shape('axis', CADShapeType.edge),
          path = _shape('path', CADShapeType.wire),
          profile2 = _shape('profile2', CADShapeType.face);
      expect((await api.extrude(profile, distance: 10)).success, isTrue);
      expect((await api.revolve(profile, axis, angle: 180)).success, isTrue);
      expect((await api.sweep(profile, path)).success, isTrue);
      expect((await api.loft([profile, profile2])).success, isTrue);
      expect(api.engine.graph.nodes, hasLength(4));
      expect(api.engine.runtime.runtime.analytics.operations, 4);
    },
  );
  test('boolean engine validates inputs and records dependencies', () async {
    final a = _shape('a', CADShapeType.solid),
        b = _shape('b', CADShapeType.solid);
    expect((await api.union([a, b])).success, isTrue);
    expect((await api.subtract(a, b)).success, isTrue);
    expect((await api.intersect([a, b])).success, isTrue);
    expect(() => api.union([a]), throwsArgumentError);
  });
  test('unsupported backend returns explicit unavailable feature', () async {
    final unavailable = FeatureApi(
      FeatureEngine(
        projectId: 'p',
        kernel: _UnavailableFeatureKernel(),
        repository: FeatureRepository(root),
      ),
    );
    final result = await unavailable.extrude(
      _shape('profile', CADShapeType.face),
      distance: 1,
    );
    expect(result.unavailable, isTrue);
    expect(result.feature.output, isNull);
    expect(result.feature.diagnostics.single.code, 'backend-unavailable');
  });
  test(
    'parametric rebuild updates only downstream revisions and preserves decisions',
    () async {
      final profile = _shape('profile', CADShapeType.face);
      final first = await api.engine.execute(
        CadFeatureKind.extrude,
        [profile],
        {'distance': 10},
        humanDecisions: const {'accepted': true},
      );
      final second = await api.engine.execute(
        CadFeatureKind.offset,
        [first.feature.output!],
        {'distance': 2},
        dependencies: [first.feature.id],
      );
      await api.engine.execute(
        CadFeatureKind.extrude,
        [_shape('other', CADShapeType.face)],
        {'distance': 5},
      );
      final rebuilt = await api.engine.rebuild(
        profile.persistentId,
        _shape('profile-v2', CADShapeType.face),
      );
      expect(rebuilt, hasLength(2));
      expect(
        rebuilt.map((e) => e.feature.id),
        containsAll([first.feature.id, second.feature.id]),
      );
      expect(rebuilt.first.feature.revision, 2);
      expect(rebuilt.first.feature.humanDecisions['accepted'], isTrue);
    },
  );
  test('healing and expanded solid validation are auditable', () async {
    final solid = _shape('solid', CADShapeType.solid);
    final audit = await api.engine.healing(solid);
    expect(audit.problems.single.code, 'tiny-edge');
    expect(audit.proposed.single.operation, 'fix-shape');
    expect(audit.executed, isEmpty);
    expect(await api.engine.validateSolid(solid), hasLength(1));
  });
  test('repository persists Features History and FeatureGraph', () async {
    await api.extrude(_shape('profile', CADShapeType.face), distance: 3);
    expect(await api.engine.repository.loadAll(), hasLength(1));
    for (final path in ['Features', 'History', 'FeatureGraph']) {
      expect(
        await Directory(
          '${root.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}$path',
        ).exists(),
        isTrue,
      );
    }
  });
  test(
    'Studio feature tree and inspector expose parametric properties',
    () async {
      final feature = (await api.extrude(
        _shape('profile', CADShapeType.face),
        distance: 4,
      )).feature;
      final tree = EngineeringTreeManager();
      const integration = FeatureStudioIntegration();
      final body = integration.body('p');
      tree.add(body);
      integration.add(tree, feature, bodyId: body.id);
      final node = tree.children(body.id).single,
          sections = const PropertyInspector().inspect(
            tree.children(body.id).single,
          );
      expect(node.type.name, 'cadFeature');
      expect(
        sections
            .expand((e) => e.values.entries)
            .any((e) => e.key == 'featureId' && e.value == feature.id),
        isTrue,
      );
      expect(node.context['parameters'], {'distance': 4});
    },
  );
  test('FEL exposes exactly the production feature command surface', () {
    final names = createFeatureFELCommands().map((e) => e.name).toList();
    expect(names, [
      'EXTRUDE',
      'REVOLVE',
      'SWEEP',
      'LOFT',
      'BOOLEAN UNION',
      'BOOLEAN SUBTRACT',
      'BOOLEAN INTERSECT',
      'REBUILD FEATURES',
      'HEAL SHAPE',
      'VALIDATE SOLID',
    ]);
  });
  test('successful features integrate Engineering History and Graph', () async {
    final engineeringHistory = EngineeringHistory();
    final engineeringGraph = EngineeringGraph();
    final integrated = FeatureApi(
      FeatureEngine(
        projectId: 'p',
        kernel: _FeatureKernel(),
        repository: FeatureRepository(root),
        engineeringHistory: engineeringHistory,
        engineeringGraph: engineeringGraph,
      ),
    );
    final result = await integrated.extrude(
      _shape('profile', CADShapeType.face),
      distance: 8,
    );
    expect(engineeringHistory.query(domain: 'cad-features'), hasLength(1));
    expect(engineeringGraph.nodes, contains(result.feature.id));
    expect(
      engineeringGraph.edges.map((e) => e.relation),
      containsAll(['input', 'output']),
    );
  });
}

ShapeHandle _shape(String id, CADShapeType type) => ShapeHandle.reference(
  persistentId: id,
  kernelId: 'features',
  type: type,
  metadata: const {'closed': true},
);

class _FeatureKernel implements InterchangeGeometryKernelAPI {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'features',
    name: 'Feature contract kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({
      KernelCapability.extrude,
      KernelCapability.revolve,
      KernelCapability.sweep,
      KernelCapability.loft,
      KernelCapability.boolean,
      KernelCapability.offset,
      KernelCapability.shell,
      KernelCapability.draft,
      KernelCapability.mirror,
      KernelCapability.linearPattern,
      KernelCapability.circularPattern,
      KernelCapability.healing,
    }),
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
    kernelId: 'features',
    type: expectedType,
    fingerprint: 'fp-$persistentId',
    metadata: const {'closed': true},
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle) async => const [
    GeometryDiagnostic(
      code: 'tiny-edge',
      message: 'Tiny edge detected',
      severity: 'warning',
    ),
  ];
  @override
  Future<List<HealingProposal>> proposeHealing(ShapeHandle handle) async =>
      const [
        HealingProposal(
          id: 'h',
          operation: 'fix-shape',
          reason: 'Tiny edge',
          diagnostics: [],
        ),
      ];
  @override
  Future<ShapeHandle> importFile(
    String path,
    KernelExchangeFormat format, {
    required String projectId,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => throw UnimplementedError();
  @override
  Future<void> exportFile(
    ShapeHandle handle,
    String path,
    KernelExchangeFormat format, {
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => throw UnimplementedError();
  @override
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces, {
    required String projectId,
    required double tolerance,
  }) => throw UnimplementedError();
  @override
  Future<KernelMeshResult> mesh(
    ShapeHandle handle, {
    required String outputPath,
    required double deflection,
  }) => throw UnimplementedError();
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
}

class _UnavailableFeatureKernel extends _FeatureKernel {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'limited',
    name: 'Limited',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities.none,
  );
}
