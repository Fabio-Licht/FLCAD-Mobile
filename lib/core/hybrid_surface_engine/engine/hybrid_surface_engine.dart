import '../../adaptive_surface/continuity/surface_continuity.dart';
import '../../surface_intelligence/models/surface_models.dart';
import '../advisor/freeform_advisor.dart';
import '../analytics/hybrid_surface_analytics.dart';
import '../continuity/continuity_optimizer.dart';
import '../history/hybrid_surface_history.dart';
import '../models/hybrid_surface_models.dart';
import '../network/surface_network.dart';
import '../patch/patch_planner.dart';
import '../quality/surface_quality_predictor.dart';
import '../reconstruction/reconstruction_network.dart';
import '../regions/hybrid_region_builder.dart';
import '../repository/hybrid_surface_repository.dart';
import '../runtime/hybrid_surface_runtime.dart';
import '../strategy/hybrid_strategy_engine.dart';

class HybridSurfaceEngine {
  HybridSurfaceEngine({
    required this.repository,
    HybridSurfaceRuntime? runtime,
    HybridSurfaceHistory? history,
    HybridRegionBuilder? regions,
    HybridContinuityOptimizer? continuity,
    HybridStrategyEngine? strategies,
    PatchPlanner? patches,
    SurfaceQualityPredictor? quality,
    ReconstructionNetworkBuilder? reconstruction,
    FreeformAdvisor? advisor,
    HybridSurfaceAnalytics? analytics,
  }) : runtime = runtime ?? HybridSurfaceRuntime(),
       history = history ?? HybridSurfaceHistory(),
       regionBuilder = regions ?? const HybridRegionBuilder(),
       continuityOptimizer = continuity ?? const HybridContinuityOptimizer(),
       strategyEngine = strategies ?? const HybridStrategyEngine(),
       patchPlanner = patches ?? const PatchPlanner(),
       qualityPredictor = quality ?? const SurfaceQualityPredictor(),
       reconstructionBuilder =
           reconstruction ?? const ReconstructionNetworkBuilder(),
       advisor = advisor ?? const FreeformAdvisor(),
       analytics = analytics ?? const HybridSurfaceAnalytics();
  final HybridSurfaceRepository repository;
  final HybridSurfaceRuntime runtime;
  final HybridSurfaceHistory history;
  final HybridRegionBuilder regionBuilder;
  final HybridContinuityOptimizer continuityOptimizer;
  final HybridStrategyEngine strategyEngine;
  final PatchPlanner patchPlanner;
  final SurfaceQualityPredictor qualityPredictor;
  final ReconstructionNetworkBuilder reconstructionBuilder;
  final FreeformAdvisor advisor;
  final HybridSurfaceAnalytics analytics;
  HybridSurfaceNetwork network = HybridSurfaceNetwork();
  HybridSurfacePlan? current;
  List<SurfaceQualityPrediction> qualityPredictions = [];
  Future<HybridSurfacePlan> build(
    SurfacePlan source,
  ) => runtime.execute('build', () async {
    if (source.candidates.isEmpty) {
      throw StateError('Surface plan has no candidates');
    }
    network = HybridSurfaceNetwork();
    final shared = <SharedSurfaceBoundary>[];
    for (var i = 0; i < source.candidates.length; i++) {
      for (var j = i + 1; j < source.candidates.length; j++) {
        final a = source.candidates[i],
            b = source.candidates[j],
            boundaries = a.boundaries.toSet().intersection(
              b.boundaries.toSet(),
            ),
            sameRegion = a.regionIds.any(b.regionIds.contains);
        if (boundaries.isNotEmpty || sameRegion) {
          shared.add(
            SharedSurfaceBoundary(
              id: 'boundary-${a.id}-${b.id}',
              surfaceIds: [a.id, b.id],
              boundaryIds: boundaries.toList(),
              continuity: _lower(a.predictedContinuity, b.predictedContinuity),
              confidence: (a.confidence + b.confidence) / 2,
            ),
          );
        }
      }
    }
    for (final candidate in source.candidates) {
      final related = shared
          .where((e) => e.surfaceIds.contains(candidate.id))
          .toList();
      network.add(
        SurfaceNetworkNode(
          candidate: candidate,
          neighborIds: related
              .expand((e) => e.surfaceIds)
              .where((e) => e != candidate.id)
              .toSet()
              .toList(),
          sharedBoundaryIds: related.map((e) => e.id).toList(),
          continuity: candidate.predictedContinuity,
          dependencies: const [],
          priority: (candidate.confidence * .6 + candidate.coverage * .4).clamp(
            0,
            1,
          ),
          geometricInfluence: (candidate.coverage * .7 + candidate.quality * .3)
              .clamp(0, 1),
        ),
      );
    }
    for (final boundary in shared) {
      network.boundary(boundary);
    }
    final nodes = network.nodes.values.toList(),
        regions = regionBuilder.build(nodes),
        continuity = shared.map(continuityOptimizer.evaluate).toList(),
        strategies = strategyEngine.compare(nodes, regions),
        patchPlans = patchPlanner.plan(regions, nodes),
        reconstruction = reconstructionBuilder.build(nodes);
    qualityPredictions = strategies
        .map((e) => qualityPredictor.predict(e, shared.length))
        .toList();
    final diagnostics = <String>[
      if (shared.isEmpty)
        'No shared boundaries or neighboring regions were detected',
      if (strategies.isEmpty) 'No viable hybrid strategy',
    ];
    final plan = HybridSurfacePlan(
      id: 'hybrid-plan-${DateTime.now().microsecondsSinceEpoch}',
      projectId: source.projectId,
      nodes: nodes,
      boundaries: shared,
      regions: regions,
      continuity: continuity,
      strategies: strategies,
      selectedStrategyId: strategies.firstOrNull?.id ?? '',
      patchPlans: patchPlans,
      reconstructionNodes: reconstruction,
      createdAt: DateTime.now(),
      valid: strategies.isNotEmpty && reconstruction.length == nodes.length,
      diagnostics: diagnostics,
    );
    current = plan;
    history.record(
      HybridHistoryAction.build,
      plan.id,
      metadata: {'surfaces': nodes.length, 'regions': regions.length},
    );
    await repository.save(plan, network);
    return plan;
  });
  List<String> validate() {
    final plan = current ?? (throw StateError('No hybrid plan')),
        issues = <String>[...plan.diagnostics];
    if (plan.reconstructionNodes.length != plan.nodes.length) {
      issues.add('Reconstruction network is incomplete');
    }
    if (plan.boundaries.any((e) => e.surfaceIds.length != 2)) {
      issues.add('Invalid shared boundary');
    }
    history.record(
      HybridHistoryAction.validate,
      plan.id,
      metadata: {'issues': issues.length},
    );
    return issues;
  }

  HybridSurfaceStatistics statistics() => analytics.calculate(
    current ?? (throw StateError('No hybrid plan')),
    qualityPredictions,
  );
  FreeformAdvice explainRegion(String regionId) {
    final plan = current ?? (throw StateError('No hybrid plan')),
        region =
            plan.regions.where((e) => e.id == regionId).firstOrNull ??
            (throw StateError('Hybrid region not found'));
    history.record(
      HybridHistoryAction.explain,
      plan.id,
      metadata: {'regionId': regionId},
    );
    return advisor.advise(region, plan.nodes);
  }

  SurfaceContinuityLevel _lower(
    SurfaceContinuityLevel a,
    SurfaceContinuityLevel b,
  ) => a.index < b.index ? a : b;
}
