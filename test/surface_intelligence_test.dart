import 'dart:io';
import 'package:flcad_mobile/core/adaptive_surface/continuity/surface_continuity.dart';
import 'package:flcad_mobile/core/adaptive_surface/models/surface_geometry.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/engineering_studio/tree/engineering_tree_manager.dart';
import 'package:flcad_mobile/core/surface_intelligence/api/surface_api.dart';
import 'package:flcad_mobile/core/surface_intelligence/boundary/boundary_analysis.dart';
import 'package:flcad_mobile/core/surface_intelligence/commands/fel_surface_intelligence_commands.dart';
import 'package:flcad_mobile/core/surface_intelligence/continuity/continuity_engine.dart';
import 'package:flcad_mobile/core/surface_intelligence/engine/surface_intelligence_engine.dart';
import 'package:flcad_mobile/core/surface_intelligence/graph/surface_dependency_graph.dart';
import 'package:flcad_mobile/core/surface_intelligence/integration/surface_studio_integration.dart';
import 'package:flcad_mobile/core/surface_intelligence/models/surface_models.dart';
import 'package:flcad_mobile/core/surface_intelligence/repository/surface_repository.dart';
import 'package:flcad_mobile/core/surface_intelligence/templates/surface_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late SurfaceIntelligenceApi api;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_surface_intelligence_');
    api = SurfaceIntelligenceApi(
      SurfaceIntelligenceEngine(
        repository: SurfaceIntelligenceRepository(root),
      ),
    );
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  test(
    'surface candidates cover all requested analytical and freeform families',
    () async {
      final plan = await api.plan(_request());
      expect(
        plan.candidates.map((e) => e.kind),
        containsAll([
          SurfaceKind.plane,
          SurfaceKind.cylinder,
          SurfaceKind.cone,
          SurfaceKind.sphere,
          SurfaceKind.torus,
          SurfaceKind.revolution,
          SurfaceKind.extrusion,
          SurfaceKind.loft,
          SurfaceKind.sweep,
          SurfaceKind.nurbs,
          SurfaceKind.patch,
          SurfaceKind.freeform,
        ]),
      );
      expect(
        plan.candidates.every(
          (e) =>
              e.evidence.isNotEmpty ||
              {
                SurfaceKind.nurbs,
                SurfaceKind.patch,
                SurfaceKind.freeform,
              }.contains(e.kind),
        ),
        isTrue,
      );
      expect(plan.valid, isTrue);
    },
  );
  test(
    'strategy engine compares analytical and NURBS with explainable scores',
    () async {
      final plan = await api.plan(_request());
      expect(plan.strategies, hasLength(plan.candidates.length));
      expect(
        plan.strategies.first.score,
        greaterThanOrEqualTo(plan.strategies.last.score),
      );
      final plane = plan.candidates.firstWhere(
            (e) => e.kind == SurfaceKind.plane,
          ),
          explanation = api.explain(plane.id);
      expect(explanation.answer, contains('Analytical'));
      expect(explanation.evidenceIds, isNotEmpty);
      expect(explanation.discardedAlternatives, contains('nurbs'));
    },
  );
  test(
    'boundary analysis detects loops open edges crossings islands and holes',
    () {
      const engine = BoundaryAnalysisEngine();
      final closed = engine.analyze(const [
        BoundarySegment('a', '1', '2', regionId: 'r'),
        BoundarySegment('b', '2', '3', regionId: 'r', crossing: true),
        BoundarySegment('c', '3', '1', regionId: 'r'),
        BoundarySegment('d', '4', '5', regionId: 'island'),
        BoundarySegment('e', '5', '4', regionId: 'island'),
      ]);
      expect(closed.loops, 2);
      expect(closed.holes, 1);
      expect(closed.islands, 1);
      expect(closed.crossings, 1);
      final open = engine.analyze(const [BoundarySegment('a', '1', '2')]);
      expect(open.openEdges, 2);
    },
  );
  test('continuity estimator distinguishes G0 G1 G2 and G3', () {
    const engine = SurfaceContinuityEstimator(tolerance: .01);
    expect(
      engine
          .estimate(
            positionError: .1,
            tangentError: 0,
            curvatureError: 0,
            derivativeError: 0,
          )
          .level,
      SurfaceContinuityLevel.g0,
    );
    expect(
      engine
          .estimate(
            positionError: 0,
            tangentError: 0,
            curvatureError: .1,
            derivativeError: 0,
          )
          .level,
      SurfaceContinuityLevel.g1,
    );
    expect(
      engine
          .estimate(
            positionError: 0,
            tangentError: 0,
            curvatureError: 0,
            derivativeError: .1,
          )
          .level,
      SurfaceContinuityLevel.g2,
    );
    expect(
      engine
          .estimate(
            positionError: 0,
            tangentError: 0,
            curvatureError: 0,
            derivativeError: 0,
          )
          .level,
      SurfaceContinuityLevel.g3,
    );
  });
  test('surface graph tracks relations and rejects dependency cycles', () {
    final graph = SurfaceDependencyGraph()
      ..add('a')
      ..add('b')
      ..add('c');
    graph.connect(const SurfaceGraphEdge('a', 'b', SurfaceRelation.dependency));
    graph.connect(const SurfaceGraphEdge('b', 'c', SurfaceRelation.continuity));
    graph.connect(const SurfaceGraphEdge('a', 'c', SurfaceRelation.influence));
    expect(graph.downstream('a'), {'b', 'c'});
    expect(
      () => graph.connect(
        const SurfaceGraphEdge('b', 'a', SurfaceRelation.dependency),
      ),
      throwsStateError,
    );
  });
  test(
    'Studio planning tree and property inspector expose planning evidence',
    () async {
      final plan = await api.plan(_request()), tree = EngineeringTreeManager();
      const SurfaceStudioIntegration().populate(tree, plan);
      final candidate = tree.nodes.firstWhere(
            (e) =>
                e.type.name == 'surfaceCandidate' &&
                e.name != 'Remaining Regions',
          ),
          sections = const PropertyInspector().inspect(candidate);
      expect(tree.nodes.first.name, 'Surface Plan');
      expect(
        sections
            .expand((e) => e.values.entries)
            .any((e) => e.key == 'predictedContinuity' && e.value != null),
        isTrue,
      );
      expect(candidate.context['strategy'], isNotNull);
    },
  );
  test(
    'persistence writes all Project First planning directories and analytics',
    () async {
      await api.plan(_request());
      for (final name in [
        'SurfacePlanning',
        'SurfaceCandidates',
        'SurfaceStrategies',
        'SurfaceGraph',
      ]) {
        final directory = Directory(
          '${root.path}${Platform.pathSeparator}$name',
        );
        expect(await directory.exists(), isTrue);
        expect(await directory.list().length, 1);
      }
      expect(api.engine.runtime.metrics.single.success, isTrue);
      expect(api.engine.history.entries.single.action.name, 'plan');
    },
  );
  test('templates prepare all required engineering families', () {
    final names = const SurfaceTemplateLibrary().all.map((e) => e.id);
    expect(
      names,
      containsAll([
        'flange',
        'shaft',
        'housing',
        'sheet',
        'casting',
        'mold',
        'plastic',
        'automotive',
        'turbine',
        'aerospace',
      ]),
    );
  });
  test('FEL exposes exactly ten Surface Intelligence commands', () {
    final names = createSurfaceIntelligenceFELCommands()
        .map((e) => e.name)
        .toList();
    expect(names, [
      'PLAN SURFACES',
      'SHOW SURFACE PLAN',
      'SHOW CONTINUITY',
      'SHOW BOUNDARIES',
      'COMPARE SURFACE STRATEGIES',
      'SHOW SURFACE GRAPH',
      'LIST SURFACE CANDIDATES',
      'EXPLAIN SURFACE',
      'SHOW SURFACE SCORE',
      'VALIDATE SURFACE PLAN',
    ]);
  });
}

SurfacePlanningRequest _request() {
  const descriptions = [
    'plane planar',
    'cylinder cylindrical',
    'cone conical',
    'sphere spherical',
    'torus toroidal',
    'revolution axisymmetric',
    'extrusion constant section',
    'loft sections',
    'sweep guide curve',
    'nurbs variable curvature',
    'patch bounded freeform',
    'freeform organic',
  ];
  return SurfacePlanningRequest(
    projectId: 'p',
    regionIds: const ['r'],
    evidence: [
      for (var i = 0; i < descriptions.length; i++)
        SurfacePlanningEvidence(
          id: 'e$i',
          source: 'Recognition + AREI + DNA + Cognition + Decision',
          description: descriptions[i],
          value: .95 - i * .01,
          regionId: 'r',
          ruleIds: ['rule-$i'],
        ),
    ],
    boundaries: const [
      BoundarySegment('b1', '1', '2', regionId: 'r'),
      BoundarySegment('b2', '2', '3', regionId: 'r'),
      BoundarySegment('b3', '3', '1', regionId: 'r'),
    ],
    coverageByKind: const {SurfaceKind.plane: .98, SurfaceKind.nurbs: .9},
    positionError: 0,
    tangentError: 0,
    curvatureError: 0,
    derivativeError: 0,
  );
}
