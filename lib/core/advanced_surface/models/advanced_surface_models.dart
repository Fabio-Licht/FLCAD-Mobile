import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_boundary/models/surface_boundary_models.dart';
import '../../surface_manufacturing/models/surface_manufacturing_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum AdvancedSurfaceType {
  match,
  replace,
  rebuild,
  heal,
  stitch,
  fill,
  boundaryFill,
  gapAnalysis,
  gapClosure,
  networkOptimization,
  smartAdvisor,
}

enum AdvancedSurfaceStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

enum AdvancedContinuity { g0, g1, g2, g3 }

enum AdvancedSelectionType { face, patch, boundary, surfaceSet }

class GapAnalysisResult {
  const GapAnalysisResult({
    required this.gaps,
    required this.overlaps,
    required this.discontinuities,
    required this.openRegions,
    required this.maximumGap,
    required this.withinTolerance,
  });
  final List<String> gaps, overlaps, discontinuities, openRegions;
  final double maximumGap;
  final bool withinTolerance;
  Map<String, dynamic> toJson() => {
    'gaps': gaps,
    'overlaps': overlaps,
    'discontinuities': discontinuities,
    'openRegions': openRegions,
    'maximumGap': maximumGap,
    'withinTolerance': withinTolerance,
    'geometryModified': false,
  };
}

class SurfaceNetworkAnalysis {
  const SurfaceNetworkAnalysis({
    required this.globalContinuity,
    required this.globalQuality,
    required this.patchDistribution,
    required this.stress,
    required this.reflection,
    required this.zebra,
    required this.manufacturingScore,
  });
  final double globalContinuity,
      globalQuality,
      stress,
      reflection,
      zebra,
      manufacturingScore;
  final Map<String, int> patchDistribution;
  Map<String, dynamic> toJson() => {
    'globalContinuity': globalContinuity,
    'globalQuality': globalQuality,
    'patchDistribution': patchDistribution,
    'surfaceStress': stress,
    'reflectionScore': reflection,
    'zebraScore': zebra,
    'manufacturingScore': manufacturingScore,
    'geometryModified': false,
  };
}

class AdvancedSurfacePreview {
  const AdvancedSurfacePreview({
    required this.affectedSurfaces,
    required this.predictedQuality,
    required this.predictedContinuity,
    required this.gapAnalysis,
    required this.networkAnalysis,
  });
  final List<String> affectedSurfaces;
  final double predictedQuality, predictedContinuity;
  final GapAnalysisResult gapAnalysis;
  final SurfaceNetworkAnalysis networkAnalysis;
  Map<String, dynamic> toJson() => {
    'affectedSurfaces': affectedSurfaces,
    'predictedQuality': predictedQuality,
    'predictedContinuity': predictedContinuity,
    'gapAnalysis': gapAnalysis.toJson(),
    'networkAnalysis': networkAnalysis.toJson(),
    'geometryModified': false,
  };
}

class AdvancedSurfaceValidationResult {
  const AdvancedSurfaceValidationResult({
    required this.valid,
    required this.selfIntersection,
    required this.topology,
    required this.quality,
    required this.continuity,
    required this.constraints,
    required this.errors,
  });
  final bool valid,
      selfIntersection,
      topology,
      quality,
      continuity,
      constraints;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'selfIntersection': selfIntersection,
    'topology': topology,
    'quality': quality,
    'continuity': continuity,
    'constraints': constraints,
    'errors': errors,
  };
}

class AdvancedSurfaceAdvice {
  const AdvancedSurfaceAdvice({
    required this.strategy,
    required this.recommendations,
  });
  final AdvancedSurfaceType strategy;
  final List<String> recommendations;
  Map<String, dynamic> toJson() => {
    'strategy': strategy.name,
    'recommendations': recommendations,
    'consultative': true,
    'automaticAction': false,
    'g012Ready': true,
  };
}

class AdvancedSurfaceSession {
  const AdvancedSurfaceSession({
    required this.id,
    required this.type,
    required this.targetPatch,
    required this.selectedPatches,
    required this.selectionType,
    required this.continuity,
    required this.parameters,
    required this.constraints,
    required this.fixedRegions,
    required this.manufacturingIntent,
    required this.status,
    required this.history,
    required this.createdAt,
    this.preview,
    this.validation,
    this.advice,
    this.operationId,
    this.resultSurface,
    this.diagnostic,
  });
  final String id;
  final AdvancedSurfaceType type;
  final PatchEntity targetPatch;
  final List<PatchEntity> selectedPatches;
  final AdvancedSelectionType selectionType;
  final AdvancedContinuity continuity;
  final Map<String, dynamic> parameters;
  final List<SurfaceConstraint> constraints;
  final List<BoundaryFixedRegion> fixedRegions;
  final ManufacturingIntent? manufacturingIntent;
  final AdvancedSurfaceStatus status;
  final List<Map<String, dynamic>> history;
  final DateTime createdAt;
  final AdvancedSurfacePreview? preview;
  final AdvancedSurfaceValidationResult? validation;
  final AdvancedSurfaceAdvice? advice;
  final String? operationId, diagnostic;
  final ShapeHandle? resultSurface;
  AdvancedSurfaceSession copyWith({
    AdvancedSurfaceStatus? status,
    AdvancedSurfacePreview? preview,
    AdvancedSurfaceValidationResult? validation,
    AdvancedSurfaceAdvice? advice,
    String? operationId,
    ShapeHandle? resultSurface,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
  }) => AdvancedSurfaceSession(
    id: id,
    type: type,
    targetPatch: targetPatch,
    selectedPatches: selectedPatches,
    selectionType: selectionType,
    continuity: continuity,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    manufacturingIntent: manufacturingIntent,
    status: status ?? this.status,
    history: history ?? this.history,
    createdAt: createdAt,
    preview: preview ?? this.preview,
    validation: validation ?? this.validation,
    advice: advice ?? this.advice,
    operationId: operationId ?? this.operationId,
    resultSurface: resultSurface ?? this.resultSurface,
    diagnostic: diagnostic ?? this.diagnostic,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'targetPatch': targetPatch.id,
    'selectedPatches': selectedPatches.map((e) => e.id).toList(),
    'selectionType': selectionType.name,
    'continuity': continuity.name.toUpperCase(),
    'originalSurface': targetPatch.surface.handle?.toJson(),
    'parameters': parameters,
    'constraints': constraints.map((e) => e.toJson()).toList(),
    'fixedRegions': fixedRegions.map((e) => e.toJson()).toList(),
    'manufacturingIntent': manufacturingIntent?.toJson(),
    'status': status.name,
    'preview': preview?.toJson(),
    'validation': validation?.toJson(),
    'advisor': advice?.toJson(),
    'operationId': operationId,
    'resultSurface': resultSurface?.toJson(),
    'diagnostic': diagnostic,
    'history': history,
    'createdAt': createdAt.toIso8601String(),
  };
}
