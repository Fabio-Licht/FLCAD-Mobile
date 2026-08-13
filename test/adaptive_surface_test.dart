import 'dart:io';
import 'package:flcad_mobile/core/adaptive_surface/advisor/surface_advisor.dart';
import 'package:flcad_mobile/core/adaptive_surface/api/surface_api.dart';
import 'package:flcad_mobile/core/adaptive_surface/builders/primitive_surface_builders.dart';
import 'package:flcad_mobile/core/adaptive_surface/builders/procedural_surface_builder.dart';
import 'package:flcad_mobile/core/adaptive_surface/builders/surface_builder.dart';
import 'package:flcad_mobile/core/adaptive_surface/continuity/surface_continuity.dart';
import 'package:flcad_mobile/core/adaptive_surface/engine/adaptive_surface_engine.dart';
import 'package:flcad_mobile/core/adaptive_surface/events/surface_event.dart';
import 'package:flcad_mobile/core/adaptive_surface/graph/surface_graph.dart';
import 'package:flcad_mobile/core/adaptive_surface/intent/surface_intent_engine.dart';
import 'package:flcad_mobile/core/adaptive_surface/models/adaptive_surface.dart';
import 'package:flcad_mobile/core/adaptive_surface/models/surface_dna.dart';
import 'package:flcad_mobile/core/adaptive_surface/models/surface_geometry.dart';
import 'package:flcad_mobile/core/adaptive_surface/network/surface_network.dart';
import 'package:flcad_mobile/core/adaptive_surface/optimization/global_surface_optimizer.dart';
import 'package:flcad_mobile/core/adaptive_surface/quality/surface_quality_engine.dart';
import 'package:flcad_mobile/core/adaptive_surface/recognizers/surface_recognizer.dart';
import 'package:flcad_mobile/core/adaptive_surface/repair/surface_repair_engine.dart';
import 'package:flcad_mobile/core/adaptive_surface/runtime/surface_runtime.dart';
import 'package:flcad_mobile/core/adaptive_surface/segmentation/smart_border_engine_v2.dart';
import 'package:flcad_mobile/core/adaptive_surface/serialization/surface_repository.dart';
import 'package:flcad_mobile/core/adaptive_surface/serialization/surface_serializer.dart';
import 'package:flcad_mobile/core/adaptive_surface/solver/adaptive_surface_solver.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/smart_regions/selection/triangle_selection.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const samples = [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0)];
SurfaceBuildRequest request({SurfaceKind? kind, List<Vec3> points = samples}) =>
    SurfaceBuildRequest(
      projectId: 'p',
      sourceIds: const ['region'],
      samples: points,
      intent: 'functional',
      targetKind: kind,
    );
AdaptiveSurface surface(String id, double continuity) {
  final geometry = const ParametricSurfaceGeometry(SurfaceKind.plane, {
        'nz': 1,
      }),
      metrics = SurfaceMetrics(
        rmsError: .01,
        maxError: .02,
        meanError: .01,
        averageCurvature: 0,
        continuity: continuity,
        confidence: .9,
        pointCount: 20,
      ),
      intent = const SurfaceIntentEngine().infer(declaredIntent: 'functional');
  return AdaptiveSurface(
    id: id,
    projectId: 'p',
    name: id,
    geometry: geometry,
    mode: SurfaceMode.live,
    stage: SurfaceStage.alpha,
    status: SurfaceStatus.valid,
    sourceIds: const ['r'],
    neighborIds: const [],
    dna: createSurfaceDNA(const ['r'], geometry, 'functional'),
    metrics: metrics,
    score: const SurfaceQualityEngine().score(metrics, intent),
    intent: 'functional',
    manufacturingProcess: ManufacturingProcess.machining,
    version: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

void main() {
  test('all surface kinds share serialization infrastructure', () {
    for (final kind in SurfaceKind.values) {
      final geometry = ParametricSurfaceGeometry(
        kind,
        const {},
        controlPoints: samples,
      );
      expect(ParametricSurfaceGeometry.fromJson(geometry.toJson()).kind, kind);
    }
  });
  test('multi solver compares every viable candidate', () async {
    final result = await AdaptiveSurfaceSolver([
      PlaneSurfaceBuilder(),
      SphereSurfaceBuilder(),
      PatchSurfaceBuilder(),
    ]).solve(request());
    expect(result.candidates.length, 3);
    expect(result.scores, contains(result.best.solverId));
  });
  test('explicit procedural kinds use portable recipes', () async {
    final result = await ProceduralSurfaceBuilder().build(
      request(kind: SurfaceKind.loft),
    );
    expect(result.geometry.kind, SurfaceKind.loft);
    expect(result.metadata['requiresDownstreamKernel'], isTrue);
  });
  test(
    'recognition, intent, advisor and quality produce explainable data',
    () async {
      final recognized = await const AlphaSurfaceRecognizer().recognize(
        request(),
      );
      expect(recognized.first.kind, SurfaceKind.plane);
      final intent = const SurfaceIntentEngine().infer(
        declaredIntent: 'machining',
      );
      expect(intent.weights['manufacturing'], .5);
      expect(
        (await const RuleBasedSurfaceAdvisor().advise(
          request(),
        )).single.continuity,
        'G2',
      );
      expect(surface('s', .8).score.total, inInclusiveRange(0, 1));
    },
  );
  test(
    'continuity, network and global optimization operate on a network',
    () async {
      var network = SurfaceNetwork()
          .add(surface('a', .2))
          .add(surface('b', .8));
      network = network.connect('a', 'b', SurfaceContinuityLevel.g2);
      expect(network.neighbors('a').single.id, 'b');
      final evaluation = const SurfaceContinuityEngine(
        tolerance: .1,
      ).evaluate(network.constraints.single, .01, .01, .01);
      expect(evaluation.satisfied, isTrue);
      final optimized = await const GlobalSurfaceOptimizer().optimize(network);
      expect(
        optimized.network.surfaces['a']!.metrics.continuity,
        greaterThan(.2),
      );
    },
  );
  test('REKG tracks cross-domain impact and round trips', () {
    final graph = SurfaceGraph()
      ..add(const EngineeringNode('region', EngineeringNodeKind.region, {}))
      ..add(const EngineeringNode('surface', EngineeringNodeKind.surface, {}))
      ..add(const EngineeringNode('solid', EngineeringNodeKind.solid, {}))
      ..connect('region', 'surface', 'derives')
      ..connect('surface', 'solid', 'prepares');
    expect(graph.impact('region'), {'surface', 'solid'});
    expect(SurfaceGraph.fromJson(graph.toJson()).dependencies('surface'), {
      'region',
    });
  });
  test('border analysis and preparation reuse Smart Regions topology', () {
    final mesh = MeshTopology(
          id: 'm',
          vertices: samples,
          triangles: const [Triangle(0, 1, 2), Triangle(0, 2, 3)],
        ),
        selection = TriangleSelection([0, 1]),
        analysis = const SmartBorderEngineV2().analyze(mesh, selection);
    expect(analysis.confidence, closeTo(1, 1e-6));
    expect(
      const SmartBorderEngineV2().prepare(mesh, selection).indices,
      selection.indices,
    );
  });
  test('repair, DNA and serialization preserve progressive surface', () {
    final original = surface('s', .5),
        repaired = const SurfaceRepairEngine().repair(original, {
          SurfaceRepairAction.smoothNoise,
        });
    expect(repaired.version, 2);
    final restored = SurfaceSerializer.fromJson(
      SurfaceSerializer.toJson(repaired),
    );
    expect(restored.dna.hash, original.dna.hash);
    expect(restored.stage, SurfaceStage.alpha);
  });
  test('runtime executes solver in background isolate', () async {
    final result = await IsolateSurfaceRuntime([
      PlaneSurfaceBuilder(),
      PatchSurfaceBuilder(),
    ]).solve(request());
    expect(
      result.best.geometry.kind,
      isIn([SurfaceKind.plane, SurfaceKind.patch]),
    );
  });
  test('FEL exposes complete surface pipeline vocabulary', () {
    final registry = createNativeCommandRegistry();
    for (final name in [
      'CREATE SURFACE',
      'FIT SURFACE',
      'PATCH',
      'BLEND',
      'FILL',
      'SWEEP',
      'LOFT',
      'OFFSET SURFACE',
      'VALIDATE SURFACE',
      'OPTIMIZE SURFACE',
      'REBUILD SURFACE',
    ]) {
      expect(registry.find(name), isNotNull);
    }
  });
  test(
    'API persists Live surface, graph, history and events Project First',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad_surface_');
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
            storage: LocalStorageService(rootDirectory: root),
          ),
          project = await projects.create(name: 'Part', client: 'Client'),
          repository = SurfaceRepository(projects: projects),
          bus = SurfaceEventBus(),
          events = <SurfaceEvent>[];
      bus.subscribe(events.add);
      final api = SurfaceApi(
        engine: AdaptiveSurfaceEngine(repository: repository, events: bus),
      );
      final created = await api.create(
        projectId: project.id,
        name: 'Base',
        request: SurfaceBuildRequest(
          projectId: project.id,
          sourceIds: const ['region'],
          samples: samples,
          intent: 'support',
        ),
        sourceKinds: const {'region': EngineeringNodeKind.region},
      );
      expect((await api.list(project.id)).single.id, created.id);
      expect(
        (await api.rebuild(
          created,
          SurfaceBuildRequest(
            projectId: project.id,
            sourceIds: const ['region'],
            samples: samples,
            intent: 'support',
          ),
        )).version,
        1,
      );
      final optimized = await api.refine(created, SurfaceStage.optimized);
      expect(optimized.stage, SurfaceStage.optimized);
      expect(await api.validate(optimized), isTrue);
      await api.optimizeNetwork(SurfaceNetwork().add(optimized));
      final directory = await projects.directoryFor(project.id);
      for (final name in [
        'surfaces.json',
        'surface_graph.json',
        'surface_history.json',
        'surface_network.json',
      ]) {
        expect(await File('${directory.path}/Surfaces/$name').exists(), isTrue);
      }
      expect(
        events.map((e) => e.type),
        containsAll([
          SurfaceEventType.created,
          SurfaceEventType.refined,
          SurfaceEventType.validated,
        ]),
      );
    },
  );
}
