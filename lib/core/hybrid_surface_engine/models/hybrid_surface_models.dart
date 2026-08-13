import '../../adaptive_surface/continuity/surface_continuity.dart';
import '../../surface_intelligence/models/surface_models.dart';

enum HybridRegionKind { analytical, analyticalTransition, freeformPatch, mixed }

enum PatchPlanKind { patch, blend, transition, extension }

class SharedSurfaceBoundary {
  const SharedSurfaceBoundary({
    required this.id,
    required this.surfaceIds,
    required this.boundaryIds,
    required this.continuity,
    required this.confidence,
  });
  final String id;
  final List<String> surfaceIds, boundaryIds;
  final SurfaceContinuityLevel continuity;
  final double confidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'surfaceIds': surfaceIds,
    'boundaryIds': boundaryIds,
    'continuity': continuity.name,
    'confidence': confidence,
  };
}

class SurfaceNetworkNode {
  const SurfaceNetworkNode({
    required this.candidate,
    required this.neighborIds,
    required this.sharedBoundaryIds,
    required this.continuity,
    required this.dependencies,
    required this.priority,
    required this.geometricInfluence,
  });
  final SurfaceCandidate candidate;
  final List<String> neighborIds, sharedBoundaryIds, dependencies;
  final SurfaceContinuityLevel continuity;
  final double priority, geometricInfluence;
  Map<String, dynamic> toJson() => {
    'candidate': candidate.toJson(),
    'neighborIds': neighborIds,
    'sharedBoundaryIds': sharedBoundaryIds,
    'continuity': continuity.name,
    'dependencies': dependencies,
    'priority': priority,
    'geometricInfluence': geometricInfluence,
  };
}

class HybridRegion {
  const HybridRegion({
    required this.id,
    required this.kind,
    required this.surfaceIds,
    required this.regionIds,
    required this.confidence,
    required this.explanation,
  });
  final String id, explanation;
  final HybridRegionKind kind;
  final List<String> surfaceIds, regionIds;
  final double confidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'surfaceIds': surfaceIds,
    'regionIds': regionIds,
    'confidence': confidence,
    'explanation': explanation,
  };
}

class ContinuityOptimization {
  const ContinuityOptimization({
    required this.boundaryId,
    required this.level,
    required this.difficulty,
    required this.cost,
    required this.robustness,
    required this.impact,
  });
  final String boundaryId;
  final SurfaceContinuityLevel level;
  final double difficulty, cost, robustness, impact;
}

class SurfaceQualityPrediction {
  const SurfaceQualityPrediction({
    required this.strategyId,
    required this.expectedError,
    required this.stability,
    required this.continuity,
    required this.editability,
    required this.reuse,
    required this.reconstructionTime,
  });
  final String strategyId;
  final double expectedError, stability, continuity, editability, reuse;
  final Duration reconstructionTime;
}

class HybridStrategy {
  const HybridStrategy({
    required this.id,
    required this.name,
    required this.surfaceIds,
    required this.score,
    required this.quality,
    required this.cost,
    required this.maintainability,
    required this.robustness,
    required this.editability,
    required this.inspectability,
    required this.manufacturability,
    required this.explanation,
  });
  final String id, name, explanation;
  final List<String> surfaceIds;
  final double score,
      quality,
      cost,
      maintainability,
      robustness,
      editability,
      inspectability,
      manufacturability;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'surfaceIds': surfaceIds,
    'score': score,
    'quality': quality,
    'cost': cost,
    'maintainability': maintainability,
    'robustness': robustness,
    'editability': editability,
    'inspectability': inspectability,
    'manufacturability': manufacturability,
    'explanation': explanation,
  };
}

class PatchPlan {
  const PatchPlan({
    required this.id,
    required this.kind,
    required this.regionIds,
    required this.boundaryIds,
    required this.guideRequired,
    required this.explanation,
  });
  final String id, explanation;
  final PatchPlanKind kind;
  final List<String> regionIds, boundaryIds;
  final bool guideRequired;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'regionIds': regionIds,
    'boundaryIds': boundaryIds,
    'guideRequired': guideRequired,
    'explanation': explanation,
  };
}

class ReconstructionSurfaceNode {
  const ReconstructionSurfaceNode({
    required this.id,
    required this.candidateId,
    required this.builder,
    required this.dependencies,
    required this.continuity,
    required this.validation,
    required this.healing,
    required this.shapeGeneration,
  });
  final String id, candidateId, builder, validation, healing, shapeGeneration;
  final List<String> dependencies;
  final SurfaceContinuityLevel continuity;
  Map<String, dynamic> toJson() => {
    'id': id,
    'candidateId': candidateId,
    'builder': builder,
    'dependencies': dependencies,
    'continuity': continuity.name,
    'validation': validation,
    'healing': healing,
    'shapeGeneration': shapeGeneration,
  };
}

class HybridSurfacePlan {
  const HybridSurfacePlan({
    required this.id,
    required this.projectId,
    required this.nodes,
    required this.boundaries,
    required this.regions,
    required this.continuity,
    required this.strategies,
    required this.selectedStrategyId,
    required this.patchPlans,
    required this.reconstructionNodes,
    required this.createdAt,
    required this.valid,
    required this.diagnostics,
  });
  final String id, projectId, selectedStrategyId;
  final List<SurfaceNetworkNode> nodes;
  final List<SharedSurfaceBoundary> boundaries;
  final List<HybridRegion> regions;
  final List<ContinuityOptimization> continuity;
  final List<HybridStrategy> strategies;
  final List<PatchPlan> patchPlans;
  final List<ReconstructionSurfaceNode> reconstructionNodes;
  final DateTime createdAt;
  final bool valid;
  final List<String> diagnostics;
}
