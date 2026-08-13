import '../../adaptive_surface/continuity/surface_continuity.dart';
import '../../adaptive_surface/models/surface_geometry.dart';

enum SurfaceClassification { analytical, transition, freeform, hybrid }

class SurfacePlanningEvidence {
  const SurfacePlanningEvidence({
    required this.id,
    required this.source,
    required this.description,
    required this.value,
    this.regionId,
    this.ruleIds = const [],
  });
  final String id, source, description;
  final double value;
  final String? regionId;
  final List<String> ruleIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'description': description,
    'value': value,
    'regionId': regionId,
    'ruleIds': ruleIds,
  };
}

class BoundarySegment {
  const BoundarySegment(
    this.id,
    this.startId,
    this.endId, {
    this.regionId,
    this.crossing = false,
  });
  final String id, startId, endId;
  final String? regionId;
  final bool crossing;
}

class BoundaryReport {
  const BoundaryReport({
    required this.loops,
    required this.openEdges,
    required this.regions,
    required this.crossings,
    required this.islands,
    required this.holes,
    required this.quality,
  });
  final int loops, openEdges, regions, crossings, islands, holes;
  final double quality;
  Map<String, dynamic> toJson() => {
    'loops': loops,
    'openEdges': openEdges,
    'regions': regions,
    'crossings': crossings,
    'islands': islands,
    'holes': holes,
    'quality': quality,
  };
}

class SurfaceCandidate {
  const SurfaceCandidate({
    required this.id,
    required this.kind,
    required this.classification,
    required this.confidence,
    required this.evidence,
    required this.regionIds,
    required this.boundaries,
    required this.quality,
    required this.coverage,
    required this.predictedContinuity,
    required this.justification,
  });
  final String id, justification;
  final SurfaceKind kind;
  final SurfaceClassification classification;
  final double confidence, quality, coverage;
  final List<SurfacePlanningEvidence> evidence;
  final List<String> regionIds, boundaries;
  final SurfaceContinuityLevel predictedContinuity;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'classification': classification.name,
    'confidence': confidence,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'regionIds': regionIds,
    'boundaries': boundaries,
    'quality': quality,
    'coverage': coverage,
    'predictedContinuity': predictedContinuity.name,
    'justification': justification,
  };
}

class SurfaceStrategy {
  const SurfaceStrategy({
    required this.id,
    required this.candidateId,
    required this.score,
    required this.cost,
    required this.robustness,
    required this.maintainability,
    required this.predictedQuality,
    required this.explanation,
  });
  final String id, candidateId, explanation;
  final double score, cost, robustness, maintainability, predictedQuality;
  Map<String, dynamic> toJson() => {
    'id': id,
    'candidateId': candidateId,
    'score': score,
    'cost': cost,
    'robustness': robustness,
    'maintainability': maintainability,
    'predictedQuality': predictedQuality,
    'explanation': explanation,
  };
}

class SurfacePlan {
  const SurfacePlan({
    required this.id,
    required this.projectId,
    required this.candidates,
    required this.strategies,
    required this.selectedStrategyIds,
    required this.boundaryReport,
    required this.createdAt,
    required this.valid,
    required this.diagnostics,
  });
  final String id, projectId;
  final List<SurfaceCandidate> candidates;
  final List<SurfaceStrategy> strategies;
  final List<String> selectedStrategyIds;
  final BoundaryReport boundaryReport;
  final DateTime createdAt;
  final bool valid;
  final List<String> diagnostics;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'candidates': candidates.map((e) => e.toJson()).toList(),
    'strategies': strategies.map((e) => e.toJson()).toList(),
    'selectedStrategyIds': selectedStrategyIds,
    'boundaryReport': boundaryReport.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'valid': valid,
    'diagnostics': diagnostics,
  };
}

class ContinuityPrediction {
  const ContinuityPrediction(this.level, this.confidence, this.explanation);
  final SurfaceContinuityLevel level;
  final double confidence;
  final String explanation;
}
