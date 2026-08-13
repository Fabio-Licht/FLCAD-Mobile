import '../../adaptive_surface/models/surface_geometry.dart';
import '../advisor/surface_advisor.dart';
import '../boundary/boundary_analysis.dart';
import '../continuity/continuity_engine.dart';
import '../graph/surface_dependency_graph.dart';
import '../history/surface_history.dart';
import '../models/surface_models.dart';
import '../repository/surface_repository.dart';
import '../runtime/surface_runtime.dart';
import '../strategy/surface_strategy_engine.dart';

class SurfacePlanningRequest {
  const SurfacePlanningRequest({
    required this.projectId,
    required this.evidence,
    required this.boundaries,
    this.regionIds = const [],
    this.coverageByKind = const {},
    this.positionError = .001,
    this.tangentError = .01,
    this.curvatureError = .05,
    this.derivativeError = .1,
  });
  final String projectId;
  final List<SurfacePlanningEvidence> evidence;
  final List<BoundarySegment> boundaries;
  final List<String> regionIds;
  final Map<SurfaceKind, double> coverageByKind;
  final double positionError, tangentError, curvatureError, derivativeError;
}

class SurfaceIntelligenceEngine {
  SurfaceIntelligenceEngine({
    required this.repository,
    SurfaceIntelligenceRuntime? runtime,
    SurfaceIntelligenceHistory? history,
    BoundaryAnalysisEngine? boundary,
    SurfaceContinuityEstimator? continuity,
    SurfaceStrategyEngine? strategy,
    SurfaceIntelligenceAdvisor? advisor,
  }) : runtime = runtime ?? SurfaceIntelligenceRuntime(),
       history = history ?? SurfaceIntelligenceHistory(),
       boundary = boundary ?? const BoundaryAnalysisEngine(),
       continuity = continuity ?? const SurfaceContinuityEstimator(),
       strategy = strategy ?? const SurfaceStrategyEngine(),
       advisor = advisor ?? const SurfaceIntelligenceAdvisor();
  final SurfaceIntelligenceRepository repository;
  final SurfaceIntelligenceRuntime runtime;
  final SurfaceIntelligenceHistory history;
  final BoundaryAnalysisEngine boundary;
  final SurfaceContinuityEstimator continuity;
  final SurfaceStrategyEngine strategy;
  final SurfaceIntelligenceAdvisor advisor;
  final SurfaceDependencyGraph graph = SurfaceDependencyGraph();
  SurfacePlan? current;

  Future<SurfacePlan> plan(
    SurfacePlanningRequest request,
  ) => runtime.execute('plan', () async {
    final boundaryReport = boundary.analyze(request.boundaries);
    final prediction = continuity.estimate(
      positionError: request.positionError,
      tangentError: request.tangentError,
      curvatureError: request.curvatureError,
      derivativeError: request.derivativeError,
    );
    final candidates = _candidates(request, boundaryReport, prediction);
    final strategies = strategy.compare(candidates);
    final selected = <String>[];
    for (final region in request.regionIds) {
      final ids = candidates
          .where((e) => e.regionIds.contains(region))
          .map((e) => e.id)
          .toSet();
      final winner = strategies
          .where((e) => ids.contains(e.candidateId))
          .firstOrNull;
      if (winner != null) selected.add(winner.id);
    }
    if (request.regionIds.isEmpty && strategies.isNotEmpty) {
      selected.add(strategies.first.id);
    }
    for (final candidate in candidates) {
      graph.add(candidate.id);
    }
    final plan = SurfacePlan(
      id: 'surface-plan-${DateTime.now().microsecondsSinceEpoch}',
      projectId: request.projectId,
      candidates: candidates,
      strategies: strategies,
      selectedStrategyIds: selected,
      boundaryReport: boundaryReport,
      createdAt: DateTime.now(),
      valid: candidates.isNotEmpty && selected.isNotEmpty,
      diagnostics: [
        if (request.evidence.isEmpty) 'No engineering evidence supplied',
        if (boundaryReport.openEdges > 0)
          '${boundaryReport.openEdges} open boundary vertices require resolution',
      ],
    );
    current = plan;
    history.record(
      SurfaceHistoryAction.plan,
      plan.id,
      metadata: {'candidateCount': candidates.length},
    );
    await repository.save(plan, graph);
    return plan;
  });

  List<SurfaceCandidate> _candidates(
    SurfacePlanningRequest request,
    BoundaryReport boundaries,
    ContinuityPrediction prediction,
  ) {
    const kinds = <SurfaceKind>[
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
    ];
    final result = <SurfaceCandidate>[];
    for (final kind in kinds) {
      final keywords = _keywords(kind);
      final evidence = request.evidence
          .where(
            (e) => keywords.any(
              (k) =>
                  e.description.toLowerCase().contains(k) ||
                  e.source.toLowerCase().contains(k),
            ),
          )
          .toList();
      if (evidence.isEmpty &&
          !{
            SurfaceKind.nurbs,
            SurfaceKind.patch,
            SurfaceKind.freeform,
          }.contains(kind)) {
        continue;
      }
      final base = evidence.isEmpty
          ? 0.2
          : evidence.map((e) => e.value).reduce((a, b) => a + b) /
                evidence.length;
      final coverage =
          request.coverageByKind[kind] ?? (evidence.isEmpty ? 0.25 : 0.75);
      final confidence =
          (base * 0.65 + boundaries.quality * 0.15 + coverage * 0.2)
              .clamp(0, 1)
              .toDouble();
      final regions = {
        ...request.regionIds,
        ...evidence.map((e) => e.regionId).whereType<String>(),
      }.toList();
      result.add(
        SurfaceCandidate(
          id: '${request.projectId}-${kind.name}-${result.length + 1}',
          kind: kind,
          classification: _classification(kind, evidence),
          confidence: confidence,
          evidence: evidence,
          regionIds: regions,
          boundaries: request.boundaries.map((e) => e.id).toList(),
          quality: (boundaries.quality * 0.5 + confidence * 0.5)
              .clamp(0, 1)
              .toDouble(),
          coverage: coverage.clamp(0, 1).toDouble(),
          predictedContinuity: prediction.level,
          justification: evidence.isEmpty
              ? 'Fallback hypothesis retained for unresolved geometry'
              : 'Supported by ${evidence.map((e) => e.source).toSet().join(', ')} evidence',
        ),
      );
    }
    return result;
  }

  List<String> _keywords(SurfaceKind kind) => switch (kind) {
    SurfaceKind.plane => ['plane', 'planar'],
    SurfaceKind.cylinder => ['cylinder', 'cylindrical'],
    SurfaceKind.cone => ['cone', 'conical'],
    SurfaceKind.sphere => ['sphere', 'spherical'],
    SurfaceKind.torus => ['torus', 'toroidal'],
    SurfaceKind.revolution => ['revolution', 'revolve', 'axisymmetric'],
    SurfaceKind.extrusion => ['extrusion', 'extruded', 'constant section'],
    SurfaceKind.loft => ['loft', 'sections'],
    SurfaceKind.sweep => ['sweep', 'guide curve'],
    SurfaceKind.nurbs => ['nurbs', 'variable curvature'],
    SurfaceKind.patch => ['patch', 'bounded freeform'],
    SurfaceKind.freeform => ['freeform', 'organic'],
    _ => [kind.name],
  };

  SurfaceClassification _classification(
    SurfaceKind kind,
    List<SurfacePlanningEvidence> evidence,
  ) {
    if ({
      SurfaceKind.plane,
      SurfaceKind.cylinder,
      SurfaceKind.cone,
      SurfaceKind.sphere,
      SurfaceKind.torus,
      SurfaceKind.revolution,
      SurfaceKind.extrusion,
    }.contains(kind)) {
      return SurfaceClassification.analytical;
    }
    if ({
      SurfaceKind.loft,
      SurfaceKind.sweep,
      SurfaceKind.patch,
    }.contains(kind)) {
      return SurfaceClassification.transition;
    }
    if (kind == SurfaceKind.nurbs || kind == SurfaceKind.freeform) {
      return evidence.any(
            (e) => e.description.toLowerCase().contains('analytic'),
          )
          ? SurfaceClassification.hybrid
          : SurfaceClassification.freeform;
    }
    return SurfaceClassification.hybrid;
  }

  SurfaceExplanation explain(String candidateId) {
    final plan = current ?? (throw StateError('No surface plan'));
    final candidate =
        plan.candidates.where((e) => e.id == candidateId).firstOrNull ??
        (throw StateError('Candidate $candidateId not found'));
    history.record(
      SurfaceHistoryAction.explain,
      plan.id,
      metadata: {'candidateId': candidateId},
    );
    return advisor.explain(candidate, plan.candidates);
  }

  List<String> validate(SurfacePlan plan) {
    final diagnostics = <String>[...plan.diagnostics];
    if (plan.selectedStrategyIds.isEmpty) {
      diagnostics.add('No selected surface strategy');
    }
    if (plan.candidates.any((e) => e.confidence < 0 || e.confidence > 1)) {
      diagnostics.add('Candidate confidence outside range');
    }
    history.record(
      SurfaceHistoryAction.validate,
      plan.id,
      metadata: {'diagnosticCount': diagnostics.length},
    );
    return diagnostics;
  }
}
