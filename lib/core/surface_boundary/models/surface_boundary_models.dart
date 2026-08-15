import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum BoundaryOperationType {
  move,
  offset,
  rotate,
  scale,
  project,
  extend,
  trim,
  match,
  smooth,
  smart,
  manufacturing,
}

enum BoundaryEditStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

enum BoundaryFixedRegionType {
  boundary,
  surface,
  curve,
  point,
  patch,
  lockedFeature,
}

enum BoundaryContinuity { g0, g1, g2, g3 }

class BoundaryFixedRegion {
  const BoundaryFixedRegion({
    required this.id,
    required this.type,
    required this.targetId,
    this.parameters = const {},
  });
  final String id, targetId;
  final BoundaryFixedRegionType type;
  final Map<String, dynamic> parameters;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'targetId': targetId,
    'parameters': parameters,
  };
}

class BoundaryAnalysis {
  const BoundaryAnalysis({
    required this.originalLength,
    required this.predictedLength,
    required this.continuity,
    required this.curvature,
    required this.stress,
    required this.twist,
    required this.quality,
    required this.manufacturingScore,
  });
  final double originalLength,
      predictedLength,
      curvature,
      stress,
      twist,
      quality,
      manufacturingScore;
  final BoundaryContinuity continuity;
  Map<String, dynamic> toJson() => {
    'originalLength': originalLength,
    'predictedLength': predictedLength,
    'lengthChange': predictedLength - originalLength,
    'continuity': continuity.name.toUpperCase(),
    'curvature': curvature,
    'predictedStress': stress,
    'predictedTwist': twist,
    'quality': quality,
    'manufacturingScore': manufacturingScore,
  };
}

class BoundaryPreview {
  const BoundaryPreview({
    required this.newPosition,
    required this.reflection,
    required this.zebra,
    required this.heatMap,
    required this.analysis,
    required this.affectedRegions,
  });
  final List<double> newPosition;
  final double reflection, zebra;
  final Map<String, double> heatMap;
  final BoundaryAnalysis analysis;
  final List<String> affectedRegions;
  Map<String, dynamic> toJson() => {
    'newPosition': newPosition,
    'predictedReflection': reflection,
    'predictedZebra': zebra,
    'heatMap': heatMap,
    'analysis': analysis.toJson(),
    'affectedRegions': affectedRegions,
    'geometryModified': false,
  };
}

class BoundaryValidationResult {
  const BoundaryValidationResult({
    required this.valid,
    required this.selfIntersection,
    required this.boundary,
    required this.continuity,
    required this.constraints,
    required this.quality,
    required this.errors,
  });
  final bool valid,
      selfIntersection,
      boundary,
      continuity,
      constraints,
      quality;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'selfIntersection': selfIntersection,
    'boundary': boundary,
    'continuity': continuity,
    'constraints': constraints,
    'quality': quality,
    'errors': errors,
  };
}

class BoundaryAdvice {
  const BoundaryAdvice({required this.strategy, required this.recommendations});
  final BoundaryOperationType strategy;
  final List<String> recommendations;
  Map<String, dynamic> toJson() => {
    'strategy': strategy.name,
    'recommendations': recommendations,
    'consultative': true,
    'automaticAction': false,
  };
}

class SurfaceBoundarySession {
  const SurfaceBoundarySession({
    required this.id,
    required this.type,
    required this.patch,
    required this.boundary,
    required this.parameters,
    required this.constraints,
    required this.fixedRegions,
    required this.continuity,
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
  final BoundaryOperationType type;
  final PatchEntity patch;
  final BoundaryEntity boundary;
  final Map<String, dynamic> parameters;
  final List<SurfaceConstraint> constraints;
  final List<BoundaryFixedRegion> fixedRegions;
  final BoundaryContinuity continuity;
  final BoundaryEditStatus status;
  final List<Map<String, dynamic>> history;
  final DateTime createdAt;
  final BoundaryPreview? preview;
  final BoundaryValidationResult? validation;
  final BoundaryAdvice? advice;
  final String? operationId, diagnostic;
  final ShapeHandle? resultSurface;
  SurfaceBoundarySession copyWith({
    BoundaryEditStatus? status,
    BoundaryPreview? preview,
    BoundaryValidationResult? validation,
    BoundaryAdvice? advice,
    String? operationId,
    ShapeHandle? resultSurface,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
  }) => SurfaceBoundarySession(
    id: id,
    type: type,
    patch: patch,
    boundary: boundary,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    continuity: continuity,
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
    'patch': patch.id,
    'boundary': boundary.id,
    'originalSurface': patch.surface.handle?.toJson(),
    'parameters': parameters,
    'constraints': constraints.map((e) => e.toJson()).toList(),
    'fixedRegions': fixedRegions.map((e) => e.toJson()).toList(),
    'continuity': continuity.name.toUpperCase(),
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
