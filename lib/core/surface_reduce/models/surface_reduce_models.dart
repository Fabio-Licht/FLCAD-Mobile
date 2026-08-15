import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum ReduceType {
  radius,
  offset,
  direction,
  untilTarget,
  smart,
  manufacturing,
  feature,
  local,
  global,
  progressive,
  constraintDriven,
}

enum ReduceStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

enum ReduceDirectionType { vector, axis, plane, averageNormal, custom }

enum FixedRegionType { distance, boundary, surface, curve, point, patch }

enum ReduceContinuity { g0, g1, g2, g3 }

class FixedRegion {
  const FixedRegion({
    required this.id,
    required this.type,
    required this.targetId,
    this.distance,
    this.parameters = const {},
  });
  final String id, targetId;
  final FixedRegionType type;
  final double? distance;
  final Map<String, dynamic> parameters;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'targetId': targetId,
    'distance': distance,
    'parameters': parameters,
  };
}

class ReducePrediction {
  const ReducePrediction({
    required this.affectedRegions,
    required this.stress,
    required this.twist,
    required this.distortion,
    required this.continuity,
    required this.reflection,
    required this.zebra,
    required this.heatMap,
    required this.quality,
    required this.manufacturingScore,
  });
  final List<String> affectedRegions;
  final double stress,
      twist,
      distortion,
      reflection,
      zebra,
      quality,
      manufacturingScore;
  final ReduceContinuity continuity;
  final Map<String, double> heatMap;
  Map<String, dynamic> toJson() => {
    'affectedRegions': affectedRegions,
    'predictedStress': stress,
    'predictedTwist': twist,
    'predictedDistortion': distortion,
    'predictedContinuity': continuity.name.toUpperCase(),
    'predictedReflection': reflection,
    'predictedZebra': zebra,
    'predictedHeatMap': heatMap,
    'predictedQuality': quality,
    'manufacturingScore': manufacturingScore,
    'geometryModified': false,
  };
}

class ReduceValidationResult {
  const ReduceValidationResult({
    required this.valid,
    required this.selfIntersection,
    required this.patch,
    required this.boundary,
    required this.continuity,
    required this.constraints,
    required this.errors,
  });
  final bool valid, selfIntersection, patch, boundary, continuity, constraints;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'selfIntersection': selfIntersection,
    'patch': patch,
    'boundary': boundary,
    'continuity': continuity,
    'constraints': constraints,
    'errors': errors,
  };
}

class ReduceAdvice {
  const ReduceAdvice({
    required this.strategy,
    required this.direction,
    required this.recommendations,
  });
  final ReduceType strategy;
  final List<double> direction;
  final List<String> recommendations;
  Map<String, dynamic> toJson() => {
    'strategy': strategy.name,
    'direction': direction,
    'recommendations': recommendations,
    'consultative': true,
    'automaticAction': false,
  };
}

class SurfaceReduceSession {
  const SurfaceReduceSession({
    required this.id,
    required this.type,
    required this.patch,
    required this.parameters,
    required this.constraints,
    required this.fixedRegions,
    required this.transition,
    required this.status,
    required this.history,
    required this.createdAt,
    this.prediction,
    this.validation,
    this.advice,
    this.operationId,
    this.resultSurface,
    this.diagnostic,
  });
  final String id;
  final ReduceType type;
  final PatchEntity patch;
  final Map<String, dynamic> parameters;
  final List<SurfaceConstraint> constraints;
  final List<FixedRegion> fixedRegions;
  final ReduceContinuity transition;
  final ReduceStatus status;
  final List<Map<String, dynamic>> history;
  final DateTime createdAt;
  final ReducePrediction? prediction;
  final ReduceValidationResult? validation;
  final ReduceAdvice? advice;
  final String? operationId, diagnostic;
  final ShapeHandle? resultSurface;
  SurfaceReduceSession copyWith({
    ReduceStatus? status,
    ReducePrediction? prediction,
    ReduceValidationResult? validation,
    ReduceAdvice? advice,
    String? operationId,
    ShapeHandle? resultSurface,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
  }) => SurfaceReduceSession(
    id: id,
    type: type,
    patch: patch,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    transition: transition,
    status: status ?? this.status,
    history: history ?? this.history,
    createdAt: createdAt,
    prediction: prediction ?? this.prediction,
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
    'originalSurface': patch.surface.handle?.toJson(),
    'parameters': parameters,
    'constraints': constraints.map((e) => e.toJson()).toList(),
    'fixedRegions': fixedRegions.map((e) => e.toJson()).toList(),
    'transition': transition.name.toUpperCase(),
    'status': status.name,
    'prediction': prediction?.toJson(),
    'validation': validation?.toJson(),
    'advisor': advice?.toJson(),
    'operationId': operationId,
    'resultSurface': resultSurface?.toJson(),
    'diagnostic': diagnostic,
    'history': history,
    'createdAt': createdAt.toIso8601String(),
  };
}
