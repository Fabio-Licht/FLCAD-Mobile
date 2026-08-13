import 'dart:io';
import 'package:flcad_mobile/core/adaptive_surface/continuity/surface_continuity.dart';
import 'package:flcad_mobile/core/adaptive_surface/models/surface_geometry.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/engineering_studio/tree/engineering_tree_manager.dart';
import 'package:flcad_mobile/core/hybrid_surface_engine/api/hybrid_surface_api.dart';
import 'package:flcad_mobile/core/hybrid_surface_engine/commands/fel_hybrid_surface_commands.dart';
import 'package:flcad_mobile/core/hybrid_surface_engine/engine/hybrid_surface_engine.dart';
import 'package:flcad_mobile/core/hybrid_surface_engine/integration/hybrid_surface_studio.dart';
import 'package:flcad_mobile/core/hybrid_surface_engine/models/hybrid_surface_models.dart';
import 'package:flcad_mobile/core/hybrid_surface_engine/repository/hybrid_surface_repository.dart';
import 'package:flcad_mobile/core/surface_intelligence/models/surface_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late HybridSurfaceApi api;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_hybrid_surface_');
    api = HybridSurfaceApi(
      HybridSurfaceEngine(repository: HybridSurfaceRepository(root)),
    );
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  test(
    'Surface Network records neighbors shared boundaries continuity and influence',
    () async {
      final plan = await api.build(_source());
      expect(plan.nodes, hasLength(5));
      expect(plan.boundaries, isNotEmpty);
      final plane = plan.nodes.firstWhere(
        (e) => e.candidate.kind == SurfaceKind.plane,
      );
      expect(plane.neighborIds, isNotEmpty);
      expect(plane.sharedBoundaryIds, isNotEmpty);
      expect(plane.priority, inInclusiveRange(0, 1));
      expect(api.engine.network.neighbors(plane.candidate.id), isNotEmpty);
    },
  );
  test(
    'Hybrid Region Builder groups analytical transitions and freeform patches',
    () async {
      final plan = await api.build(_source());
      expect(plan.regions, isNotEmpty);
      expect(
        plan.regions.expand((e) => e.surfaceIds).toSet(),
        containsAll(plan.nodes.map((e) => e.candidate.id)),
      );
      expect(
        plan.regions.map((e) => e.kind),
        contains(
          anyOf(
            HybridRegionKind.analyticalTransition,
            HybridRegionKind.freeformPatch,
          ),
        ),
      );
    },
  );
  test(
    'Continuity Optimizer estimates G0-G3 difficulty cost robustness and impact',
    () async {
      final plan = await api.build(_source());
      expect(plan.continuity, isNotEmpty);
      for (final value in plan.continuity) {
        expect(
          value.level,
          anyOf(
            SurfaceContinuityLevel.g0,
            SurfaceContinuityLevel.g1,
            SurfaceContinuityLevel.g2,
            SurfaceContinuityLevel.g3,
          ),
        );
        expect(value.difficulty, inInclusiveRange(0, 1));
        expect(value.cost, inInclusiveRange(0, 1));
        expect(value.robustness, inInclusiveRange(0, 1));
        expect(value.impact, inInclusiveRange(0, 1));
      }
    },
  );
  test(
    'Hybrid Strategy Engine compares complete strategies and surface consolidation',
    () async {
      final plan = await api.build(_source());
      expect(plan.strategies.map((e) => e.id), [
        'hybrid-analytic-transition',
        'patch-network',
        'single-nurbs',
      ]);
      expect(
        plan.strategies.first.score,
        greaterThan(plan.strategies.last.score),
      );
      expect(plan.strategies.every((e) => e.explanation.isNotEmpty), isTrue);
      expect(plan.selectedStrategyId, plan.strategies.first.id);
    },
  );
  test(
    'Patch Planner and Freeform Advisor produce explainable non-geometric plans',
    () async {
      final plan = await api.build(_source());
      expect(plan.patchPlans, hasLength(plan.regions.length));
      expect(plan.patchPlans.every((e) => e.explanation.isNotEmpty), isTrue);
      final advice = api.explain(plan.regions.first.id);
      expect(advice.explanation, isNotEmpty);
      expect(advice.evidenceSurfaceIds, isNotEmpty);
    },
  );
  test(
    'Quality Predictor estimates all requested dimensions and analytics aggregates',
    () async {
      final plan = await api.build(_source()),
          quality = api.engine.qualityPredictions,
          stats = api.statistics();
      expect(quality, hasLength(3));
      expect(quality.first.expectedError, inInclusiveRange(0, 1));
      expect(quality.first.stability, inInclusiveRange(0, 1));
      expect(quality.first.continuity, inInclusiveRange(0, 1));
      expect(quality.first.editability, inInclusiveRange(0, 1));
      expect(quality.first.reuse, inInclusiveRange(0, 1));
      expect(quality.first.reconstructionTime, greaterThan(Duration.zero));
      expect(stats.surfaceCount, plan.nodes.length);
      expect(stats.hybridRegionCount, plan.regions.length);
    },
  );
  test(
    'Reconstruction Network is complete DAG intent and never executes geometry',
    () async {
      final plan = await api.build(_source());
      expect(plan.reconstructionNodes, hasLength(plan.nodes.length));
      expect(
        plan.reconstructionNodes.every(
          (e) => e.shapeGeneration == 'deferred-to-kernel',
        ),
        isTrue,
      );
      expect(
        plan.reconstructionNodes.every(
          (e) => e.builder.endsWith('-builder-contract'),
        ),
        isTrue,
      );
      expect(api.validate(), isEmpty);
    },
  );
  test(
    'Studio network and Property Inspector expose hybrid strategy details',
    () async {
      final plan = await api.build(_source()), tree = EngineeringTreeManager();
      const HybridSurfaceStudioIntegration().populate(tree, plan);
      expect(tree.nodes.first.name, 'Hybrid Surface Network');
      final node = tree.nodes.firstWhere(
            (e) =>
                e.type.name == 'hybridSurface' && e.name != 'Remaining Regions',
          ),
          sections = const PropertyInspector().inspect(node);
      expect(node.context['hybridStrategy'], plan.selectedStrategyId);
      expect(
        sections
            .expand((e) => e.values.entries)
            .any((e) => e.key == 'neighbors' && e.value != null),
        isTrue,
      );
      expect(node.context['discardedAlternatives'], isNotEmpty);
    },
  );
  test(
    'persistence writes five Project First network artifacts and runtime history',
    () async {
      await api.build(_source());
      for (final name in [
        'HybridSurface',
        'SurfaceNetwork',
        'HybridStrategies',
        'PatchPlanning',
        'ReconstructionNetwork',
      ]) {
        final directory = Directory(
          '${root.path}${Platform.pathSeparator}$name',
        );
        expect(await directory.exists(), isTrue);
        expect(await directory.list().length, 1);
      }
      expect(api.engine.runtime.metrics.single.success, isTrue);
      expect(api.engine.history.entries.single.action.name, 'build');
    },
  );
  test('FEL exposes exactly ten Hybrid Surface commands', () {
    final names = createHybridSurfaceFELCommands().map((e) => e.name).toList();
    expect(names, [
      'BUILD SURFACE NETWORK',
      'SHOW SURFACE NETWORK',
      'SHOW HYBRID REGIONS',
      'SHOW CONTINUITY GRAPH',
      'SHOW SURFACE QUALITY',
      'COMPARE HYBRID STRATEGIES',
      'SHOW PATCH PLAN',
      'SHOW RECONSTRUCTION NETWORK',
      'EXPLAIN HYBRID STRATEGY',
      'VALIDATE SURFACE NETWORK',
    ]);
  });
}

SurfacePlan _source() {
  final candidates = [
    _candidate(
      'plane',
      SurfaceKind.plane,
      ['r1'],
      ['b1'],
      .97,
      SurfaceContinuityLevel.g1,
    ),
    _candidate(
      'cylinder',
      SurfaceKind.cylinder,
      ['r1', 'r2'],
      ['b1', 'b2'],
      .94,
      SurfaceContinuityLevel.g1,
    ),
    _candidate(
      'blend',
      SurfaceKind.blend,
      ['r2'],
      ['b2', 'b3'],
      .84,
      SurfaceContinuityLevel.g2,
    ),
    _candidate(
      'patch',
      SurfaceKind.patch,
      ['r3'],
      ['b3', 'b4'],
      .78,
      SurfaceContinuityLevel.g2,
    ),
    _candidate(
      'nurbs',
      SurfaceKind.nurbs,
      ['r3'],
      ['b4'],
      .72,
      SurfaceContinuityLevel.g3,
    ),
  ];
  final strategies = [
    for (final c in candidates)
      SurfaceStrategy(
        id: 'strategy-${c.id}',
        candidateId: c.id,
        score: c.confidence,
        cost: .4,
        robustness: .8,
        maintainability: .7,
        predictedQuality: c.quality,
        explanation: 'source strategy',
      ),
  ];
  return SurfacePlan(
    id: 'source',
    projectId: 'p',
    candidates: candidates,
    strategies: strategies,
    selectedStrategyIds: strategies.map((e) => e.id).toList(),
    boundaryReport: const BoundaryReport(
      loops: 1,
      openEdges: 0,
      regions: 3,
      crossings: 0,
      islands: 0,
      holes: 0,
      quality: .9,
    ),
    createdAt: DateTime.now(),
    valid: true,
    diagnostics: const [],
  );
}

SurfaceCandidate _candidate(
  String id,
  SurfaceKind kind,
  List<String> regions,
  List<String> boundaries,
  double confidence,
  SurfaceContinuityLevel continuity,
) => SurfaceCandidate(
  id: id,
  kind: kind,
  classification: {SurfaceKind.plane, SurfaceKind.cylinder}.contains(kind)
      ? SurfaceClassification.analytical
      : kind == SurfaceKind.nurbs
      ? SurfaceClassification.freeform
      : SurfaceClassification.transition,
  confidence: confidence,
  evidence: [
    SurfacePlanningEvidence(
      id: 'e-$id',
      source: 'Surface Intelligence',
      description: kind.name,
      value: confidence,
      regionId: regions.first,
    ),
  ],
  regionIds: regions,
  boundaries: boundaries,
  quality: confidence - .05,
  coverage: confidence - .1,
  predictedContinuity: continuity,
  justification: 'evidence-based $kind',
);
