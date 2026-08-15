import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_boundary/models/surface_boundary_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum ManufacturingOperationType {
  draftSurface,
  draftAnalysis,
  manufacturingOffset,
  reliefSurface,
  punchExtension,
  dieExtension,
  springbackCompensation,
  manufacturingBlend,
  manufacturingTransition,
  smartManufacturing,
  manufacturingValidation,
}

enum ManufacturingStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

enum ManufacturingProcess {
  stamping,
  mold,
  die,
  electrode,
  machining,
  coating,
  custom,
}

class ManufacturingIntent {
  const ManufacturingIntent({
    required this.process,
    required this.objective,
    this.parameters = const {},
  });
  final ManufacturingProcess process;
  final String objective;
  final Map<String, dynamic> parameters;
  Map<String, dynamic> toJson() => {
    'process': process.name,
    'objective': objective,
    'parameters': parameters,
  };
}

class ManufacturingAnalysis {
  const ManufacturingAnalysis({
    required this.negativeRegions,
    required this.neutralRegions,
    required this.positiveRegions,
    required this.draftColorMap,
    required this.draftScore,
    required this.machiningScore,
    required this.stampingScore,
    required this.moldScore,
    required this.electrodeScore,
    required this.quality,
    required this.twistRisk,
    required this.undercutRisk,
  });
  final int negativeRegions, neutralRegions, positiveRegions;
  final Map<String, String> draftColorMap;
  final double draftScore,
      machiningScore,
      stampingScore,
      moldScore,
      electrodeScore,
      quality,
      twistRisk,
      undercutRisk;
  Map<String, dynamic> toJson() => {
    'negativeRegions': negativeRegions,
    'neutralRegions': neutralRegions,
    'positiveRegions': positiveRegions,
    'draftColorMap': draftColorMap,
    'draftScore': draftScore,
    'machiningScore': machiningScore,
    'stampingScore': stampingScore,
    'moldScore': moldScore,
    'electrodeScore': electrodeScore,
    'manufacturingQuality': quality,
    'twistRisk': twistRisk,
    'undercutRisk': undercutRisk,
    'geometryModified': false,
  };
}

class ManufacturingPreview {
  const ManufacturingPreview({
    required this.analysis,
    required this.affectedRegions,
    required this.strategyImpact,
  });
  final ManufacturingAnalysis analysis;
  final List<String> affectedRegions;
  final Map<String, double> strategyImpact;
  Map<String, dynamic> toJson() => {
    'analysis': analysis.toJson(),
    'affectedRegions': affectedRegions,
    'strategyImpact': strategyImpact,
    'geometryModified': false,
  };
}

class ManufacturingValidationResult {
  const ManufacturingValidationResult({
    required this.valid,
    required this.undercuts,
    required this.selfIntersection,
    required this.draft,
    required this.constraints,
    required this.quality,
    required this.errors,
  });
  final bool valid, undercuts, selfIntersection, draft, constraints, quality;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'undercuts': undercuts,
    'selfIntersection': selfIntersection,
    'draft': draft,
    'constraints': constraints,
    'quality': quality,
    'errors': errors,
  };
}

class ManufacturingAdvice {
  const ManufacturingAdvice({
    required this.strategy,
    required this.recommendations,
  });
  final ManufacturingOperationType strategy;
  final List<String> recommendations;
  Map<String, dynamic> toJson() => {
    'strategy': strategy.name,
    'recommendations': recommendations,
    'consultative': true,
    'automaticAction': false,
  };
}

class SurfaceManufacturingSession {
  const SurfaceManufacturingSession({
    required this.id,
    required this.type,
    required this.patch,
    required this.intent,
    required this.parameters,
    required this.constraints,
    required this.fixedRegions,
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
  final ManufacturingOperationType type;
  final PatchEntity patch;
  final ManufacturingIntent intent;
  final Map<String, dynamic> parameters;
  final List<SurfaceConstraint> constraints;
  final List<BoundaryFixedRegion> fixedRegions;
  final ManufacturingStatus status;
  final List<Map<String, dynamic>> history;
  final DateTime createdAt;
  final ManufacturingPreview? preview;
  final ManufacturingValidationResult? validation;
  final ManufacturingAdvice? advice;
  final String? operationId, diagnostic;
  final ShapeHandle? resultSurface;
  SurfaceManufacturingSession copyWith({
    ManufacturingStatus? status,
    ManufacturingPreview? preview,
    ManufacturingValidationResult? validation,
    ManufacturingAdvice? advice,
    String? operationId,
    ShapeHandle? resultSurface,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
  }) => SurfaceManufacturingSession(
    id: id,
    type: type,
    patch: patch,
    intent: intent,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
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
    'originalSurface': patch.surface.handle?.toJson(),
    'manufacturingIntent': intent.toJson(),
    'parameters': parameters,
    'constraints': constraints.map((e) => e.toJson()).toList(),
    'fixedRegions': fixedRegions.map((e) => e.toJson()).toList(),
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
