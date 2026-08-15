import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum FairType {
  fairSurface,
  localFair,
  globalFair,
  smartFair,
  surfaceRelax,
  curvatureRelax,
  reflectionOptimization,
  zebraOptimization,
  twistReduction,
  noiseReduction,
  manufacturingFair,
}

enum FairStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

enum FairFixedRegionType { boundary, surface, curve, point, patch, radius }

enum FairContinuity { g0, g1, g2, g3 }

class FairFixedRegion {
  const FairFixedRegion({
    required this.id,
    required this.type,
    required this.targetId,
    this.radius,
    this.parameters = const {},
  });
  final String id, targetId;
  final FairFixedRegionType type;
  final double? radius;
  final Map<String, dynamic> parameters;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'targetId': targetId,
    'radius': radius,
    'parameters': parameters,
  };
}

class FairPrediction {
  const FairPrediction({
    required this.affectedRegions,
    required this.surfaceEnergy,
    required this.reflection,
    required this.zebra,
    required this.curvature,
    required this.heatMap,
    required this.stress,
    required this.twist,
    required this.distortion,
    required this.quality,
    required this.manufacturingScore,
  });
  final List<String> affectedRegions;
  final double surfaceEnergy,
      reflection,
      zebra,
      curvature,
      stress,
      twist,
      distortion,
      quality,
      manufacturingScore;
  final Map<String, double> heatMap;
  Map<String, dynamic> toJson() => {
    'affectedRegions': affectedRegions,
    'surfaceEnergy': surfaceEnergy,
    'predictedReflection': reflection,
    'predictedZebra': zebra,
    'predictedCurvature': curvature,
    'predictedHeatMap': heatMap,
    'predictedStress': stress,
    'predictedTwist': twist,
    'predictedDistortion': distortion,
    'predictedQuality': quality,
    'manufacturingScore': manufacturingScore,
    'geometryModified': false,
  };
}

class FairValidationResult {
  const FairValidationResult({
    required this.valid,
    required this.selfIntersection,
    required this.continuity,
    required this.deformation,
    required this.constraints,
    required this.quality,
    required this.errors,
  });
  final bool valid,
      selfIntersection,
      continuity,
      deformation,
      constraints,
      quality;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'selfIntersection': selfIntersection,
    'continuity': continuity,
    'deformation': deformation,
    'constraints': constraints,
    'quality': quality,
    'errors': errors,
  };
}

class FairAdvice {
  const FairAdvice({
    required this.strategy,
    required this.strength,
    required this.influenceRadius,
    required this.recommendations,
  });
  final FairType strategy;
  final double strength, influenceRadius;
  final List<String> recommendations;
  Map<String, dynamic> toJson() => {
    'strategy': strategy.name,
    'strength': strength,
    'influenceRadius': influenceRadius,
    'recommendations': recommendations,
    'consultative': true,
    'automaticAction': false,
  };
}

class SurfaceFairSession {
  const SurfaceFairSession({
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
  final FairType type;
  final PatchEntity patch;
  final Map<String, dynamic> parameters;
  final List<SurfaceConstraint> constraints;
  final List<FairFixedRegion> fixedRegions;
  final FairContinuity transition;
  final FairStatus status;
  final List<Map<String, dynamic>> history;
  final DateTime createdAt;
  final FairPrediction? prediction;
  final FairValidationResult? validation;
  final FairAdvice? advice;
  final String? operationId, diagnostic;
  final ShapeHandle? resultSurface;
  SurfaceFairSession copyWith({
    FairStatus? status,
    FairPrediction? prediction,
    FairValidationResult? validation,
    FairAdvice? advice,
    String? operationId,
    ShapeHandle? resultSurface,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
  }) => SurfaceFairSession(
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
