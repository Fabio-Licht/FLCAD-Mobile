import 'dart:io';
import 'package:flcad_mobile/core/adaptive_surface/continuity/surface_continuity.dart';
import 'package:flcad_mobile/core/adaptive_surface/models/surface_geometry.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/engineering/graph/engineering_graph.dart';
import 'package:flcad_mobile/core/engineering/history/engineering_history.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/engineering_studio/tree/engineering_tree_manager.dart';
import 'package:flcad_mobile/core/surface_generation/api/surface_generation_api.dart';
import 'package:flcad_mobile/core/surface_generation/commands/fel_surface_generation_commands.dart';
import 'package:flcad_mobile/core/surface_generation/engine/surface_generation_engine.dart';
import 'package:flcad_mobile/core/surface_generation/integration/surface_generation_studio.dart';
import 'package:flcad_mobile/core/surface_generation/models/surface_generation_models.dart';
import 'package:flcad_mobile/core/surface_generation/repository/surface_generation_repository.dart';
import 'package:flcad_mobile/core/surface_intelligence/models/surface_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late SurfaceGenerationApi api;
  late EngineeringGraph engineeringGraph;
  late EngineeringHistory engineeringHistory;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_surface_generation_');
    engineeringGraph = EngineeringGraph();
    engineeringHistory = EngineeringHistory();
    api = SurfaceGenerationApi(
      SurfaceGenerationEngine(
        projectId: 'p',
        kernel: _SurfaceKernel(),
        repository: SurfaceGenerationRepository(root),
        engineeringGraph: engineeringGraph,
        engineeringHistory: engineeringHistory,
      ),
    );
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  test(
    'Plane Cylinder Cone and Sphere builders generate real kernel handles',
    () async {
      final plane = await api.plane.fromCandidate(
        _candidate(SurfaceKind.plane),
        origin: const [0, 0, 0],
        normal: const [0, 0, 1],
      );
      final cylinder = await api.cylinder.fromCandidate(
        _candidate(SurfaceKind.cylinder),
        axisOrigin: const [0, 0, 0],
        axisDirection: const [0, 0, 1],
        radius: 5,
      );
      final cone = await api.cone.fromCandidate(
        _candidate(SurfaceKind.cone),
        apex: const [0, 0, 0],
        axisDirection: const [0, 0, 1],
        semiAngle: .5,
      );
      final sphere = await api.sphere.fromCandidate(
        _candidate(SurfaceKind.sphere),
        center: const [0, 0, 0],
        radius: 3,
      );
      for (final result in [plane, cylinder, cone, sphere]) {
        expect(result.success, isTrue);
        expect(result.surface!.handle.type, CADShapeType.face);
        expect(result.completedStages, SurfacePipelineStage.values);
        expect(result.healingProposals, hasLength(1));
      }
      expect(api.engine.registry.surfaces, hasLength(4));
      expect(
        api.engine.analytics.byType.keys,
        containsAll([
          SurfaceKind.plane,
          SurfaceKind.cylinder,
          SurfaceKind.cone,
          SurfaceKind.sphere,
        ]),
      );
    },
  );
  test(
    'pre-validation returns complete diagnostics and never calls geometry builder',
    () async {
      final kernel = _SurfaceKernel(),
          engine = SurfaceGenerationEngine(
            projectId: 'p',
            kernel: kernel,
            repository: SurfaceGenerationRepository(root),
          );
      final result = await engine.generate(
        SurfaceGenerationRequest(
          candidate: _candidate(SurfaceKind.cylinder, regions: const []),
          parameters: const {'radius': -1},
        ),
      );
      expect(result.status, SurfaceGenerationStatus.invalid);
      expect(
        result.diagnostics.map((e) => e.code),
        containsAll([
          'missing-axisOrigin',
          'missing-axisDirection',
          'invalid-radius',
          'invalid-region',
        ]),
      );
      expect(kernel.createCalls, 0);
      expect(
        result.completedStages,
        containsAll([
          SurfacePipelineStage.candidateValidation,
          SurfacePipelineStage.history,
          SurfacePipelineStage.analytics,
        ]),
      );
    },
  );
  test(
    'absent backend returns unavailable without fictitious surface',
    () async {
      final unavailable = SurfaceGenerationEngine(
        projectId: 'p',
        kernel: _UnavailableSurfaceKernel(),
        repository: SurfaceGenerationRepository(root),
      );
      final result = await unavailable.generate(
        SurfaceGenerationRequest(
          candidate: _candidate(SurfaceKind.plane),
          parameters: const {
            'origin': [0, 0, 0],
            'normal': [0, 0, 1],
          },
        ),
      );
      expect(result.status, SurfaceGenerationStatus.unavailable);
      expect(result.surface, isNull);
      expect(result.diagnostics.single.code, 'backend-unavailable');
      expect(unavailable.registry.surfaces, isEmpty);
      expect(unavailable.history.entries.single.action.name, 'unavailable');
    },
  );
  test('healing sewing and repair remain auditable proposals only', () async {
    final result = await api.sphere.fromCandidate(
      _candidate(SurfaceKind.sphere),
      center: const [0, 0, 0],
      radius: 2,
    );
    expect(result.diagnostics.single.code, 'tiny-edge');
    expect(result.healingProposals.single.operation, 'fix-shape');
    expect(result.sewingSuggestions.single, contains('sewing'));
    expect(result.repairSuggestions.single, contains('repair'));
    expect(result.surface!.revision, 1);
  });
  test(
    'registry graph Engineering Graph History and advisor retain provenance',
    () async {
      final result = await api.plane.fromCandidate(
        _candidate(SurfaceKind.plane),
        origin: const [0, 0, 0],
        normal: const [0, 0, 1],
      );
      final surface = result.surface!,
          advice = api.explain(surface.surfaceId, .92);
      expect(api.engine.graph.nodes, contains(surface.surfaceId));
    expect(engineeringGraph.nodes.keys, containsAll(['r', surface.surfaceId]));
      expect(
        engineeringHistory.query(domain: 'surface-generation'),
        hasLength(1),
      );
      expect(advice.evidenceIds, ['e']);
      expect(advice.why, contains('approved Surface Intelligence evidence'));
    },
  );
  test(
    'Studio panel tree and Property Inspector expose generated surface data',
    () async {
      await api.cylinder.fromCandidate(
        _candidate(SurfaceKind.cylinder),
        axisOrigin: const [0, 0, 0],
        axisDirection: const [0, 0, 1],
        radius: 5,
      );
      final tree = EngineeringTreeManager();
      const SurfaceGenerationStudioIntegration().populate(
        tree,
        'p',
        api.engine.registry.surfaces,
      );
      final node = tree.nodes.last,
          sections = const PropertyInspector().inspect(node);
      expect(tree.nodes.first.name, 'Generated Surfaces');
      expect(node.name, 'Cylinder001');
      expect(
        sections
            .expand((e) => e.values.entries)
            .any((e) => e.key == 'shapeHandle' && e.value != null),
        isTrue,
      );
      expect(node.context['persistentId'], isNotNull);
    },
  );
  test(
    'persistence writes all generation directories and delete removes surface file',
    () async {
      final result = await api.plane.fromCandidate(
        _candidate(SurfaceKind.plane),
        origin: const [0, 0, 0],
        normal: const [0, 0, 1],
      );
      for (final name in [
        'GeneratedSurfaces',
        'SurfaceHistory',
        'SurfaceRegistry',
        'SurfaceDiagnostics',
      ]) {
        final directory = Directory(
          '${root.path}${Platform.pathSeparator}$name',
        );
        expect(await directory.exists(), isTrue);
        expect(await directory.list().isEmpty, isFalse);
      }
      await api.engine.delete(result.surface!.surfaceId);
      expect(
        await File(
          '${root.path}${Platform.pathSeparator}GeneratedSurfaces${Platform.pathSeparator}${result.surface!.surfaceId}.json',
        ).exists(),
        isFalse,
      );
    },
  );
  test(
    'analytics captures generation validation healing success and failure',
    () async {
      await api.plane.fromCandidate(
        _candidate(SurfaceKind.plane),
        origin: const [0, 0, 0],
        normal: const [0, 0, 1],
      );
      await api.engine.generate(
        SurfaceGenerationRequest(
          candidate: _candidate(SurfaceKind.sphere, regions: const []),
          parameters: const {},
        ),
      );
      expect(api.engine.analytics.metrics, hasLength(2));
      expect(api.engine.analytics.successes, 1);
      expect(api.engine.analytics.failures, 1);
      expect(api.engine.analytics.successRate, .5);
    },
  );
  test('FEL exposes exactly ten surface generation commands', () {
    final names = createSurfaceGenerationFELCommands()
        .map((e) => e.name)
        .toList();
    expect(names, [
      'GENERATE SURFACES',
      'GENERATE PLANE',
      'GENERATE CYLINDER',
      'GENERATE CONE',
      'GENERATE SPHERE',
      'VALIDATE SURFACE',
      'HEAL SURFACE',
      'SHOW GENERATED SURFACES',
      'SHOW SURFACE DIAGNOSTICS',
      'DELETE SURFACE',
    ]);
  });
}

SurfaceCandidate _candidate(
  SurfaceKind kind, {
  List<String> regions = const ['r'],
}) => SurfaceCandidate(
  id: 'candidate-${kind.name}',
  kind: kind,
  classification: SurfaceClassification.analytical,
  confidence: .95,
  evidence: const [
    SurfacePlanningEvidence(
      id: 'e',
      source: 'Recognition + Cognition',
      description: 'Analytical evidence',
      value: .95,
      regionId: 'r',
    ),
  ],
  regionIds: regions,
  boundaries: const ['b'],
  quality: .9,
  coverage: .8,
  predictedContinuity: SurfaceContinuityLevel.g1,
  justification: 'Approved analytical strategy',
);

class _SurfaceKernel implements InterchangeGeometryKernelAPI {
  int createCalls = 0;
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'surface-kernel',
    name: 'Surface contract kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({
      KernelCapability.planeSurface,
      KernelCapability.cylinderSurface,
      KernelCapability.coneSurface,
      KernelCapability.sphereSurface,
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
  }) async {
    createCalls++;
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: 'surface-kernel',
      type: expectedType,
      fingerprint: 'fp-$persistentId',
    );
  }

  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle) async => const [
    GeometryDiagnostic(
      code: 'tiny-edge',
      message: 'Review tiny edge',
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
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
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
}

class _UnavailableSurfaceKernel extends _SurfaceKernel {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'unavailable',
    name: 'Unavailable',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities.none,
  );
}
