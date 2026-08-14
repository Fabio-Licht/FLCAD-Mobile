import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum SurfaceOperationType {
  moveBoundary,
  extendSurface,
  trimSurface,
  splitSurface,
  mergeSurface,
  offsetSurface,
  replaceSurface,
  matchSurface,
  projectBoundary,
  reparameterizeSurface,
  healingOperation,
}

enum SurfaceOperationStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

enum SurfaceConstraintType {
  anchor,
  lockedBoundary,
  lockedCurve,
  lockedRegion,
  fixedPoint,
  tangency,
  curvature,
  direction,
  manufacturingIntent,
}

class SurfaceConstraint {
  const SurfaceConstraint({
    required this.id,
    required this.type,
    required this.targetId,
    this.parameters = const {},
    this.enabled = true,
  });
  final String id, targetId;
  final SurfaceConstraintType type;
  final Map<String, dynamic> parameters;
  final bool enabled;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'target': targetId,
    'parameters': parameters,
    'enabled': enabled,
  };
}

class SurfaceOperationPreview {
  const SurfaceOperationPreview({
    required this.id,
    required this.operationId,
    required this.originalSurface,
    required this.affectedPatches,
    required this.affectedBoundaries,
    required this.affectedContinuity,
    required this.kernelStatus,
    required this.createdAt,
  });
  final String id, operationId, kernelStatus;
  final ShapeHandle originalSurface;
  final List<String> affectedPatches, affectedBoundaries, affectedContinuity;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operationId,
    'originalSurface': originalSurface.toJson(),
    'affectedPatches': affectedPatches,
    'affectedBoundaries': affectedBoundaries,
    'affectedContinuity': affectedContinuity,
    'kernelStatus': kernelStatus,
    'geometryModified': false,
    'createdAt': createdAt.toIso8601String(),
  };
}

class SurfaceOperationValidation {
  const SurfaceOperationValidation({
    required this.valid,
    required this.topology,
    required this.continuity,
    required this.boundaryHealth,
    required this.patchHealth,
    required this.surfaceQuality,
    required this.constraintConflicts,
    required this.errors,
  });
  final bool valid,
      topology,
      continuity,
      boundaryHealth,
      patchHealth,
      surfaceQuality;
  final List<String> constraintConflicts, errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'topology': topology,
    'continuity': continuity,
    'boundaryHealth': boundaryHealth,
    'patchHealth': patchHealth,
    'surfaceQuality': surfaceQuality,
    'constraintConflicts': constraintConflicts,
    'errors': errors,
  };
}

class SurfaceOperationAnalytics {
  const SurfaceOperationAnalytics({
    required this.executionTime,
    required this.commits,
    required this.rollbacks,
    required this.cancellations,
    required this.validationErrors,
    required this.topologyUpdates,
    required this.continuityUpdates,
  });
  final Duration executionTime;
  final int commits,
      rollbacks,
      cancellations,
      validationErrors,
      topologyUpdates,
      continuityUpdates;
  Map<String, dynamic> toJson() => {
    'executionMicros': executionTime.inMicroseconds,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'validationErrors': validationErrors,
    'topologyUpdates': topologyUpdates,
    'continuityUpdates': continuityUpdates,
  };
}

class SurfaceOperation {
  const SurfaceOperation({
    required this.id,
    required this.type,
    required this.targetPatch,
    required this.targetSurface,
    required this.constraints,
    required this.parameters,
    required this.status,
    required this.createdAt,
    required this.executionTime,
    required this.analytics,
    this.preview,
    this.undoToken,
    this.redoToken,
    this.validation,
    this.resultSurface,
    this.diagnostic,
  });
  final String id;
  final SurfaceOperationType type;
  final PatchEntity targetPatch;
  final ShapeHandle targetSurface;
  final List<SurfaceConstraint> constraints;
  final Map<String, dynamic> parameters;
  final SurfaceOperationPreview? preview;
  final SurfaceOperationStatus status;
  final DateTime createdAt;
  final Duration executionTime;
  final String? undoToken, redoToken, diagnostic;
  final SurfaceOperationValidation? validation;
  final ShapeHandle? resultSurface;
  final SurfaceOperationAnalytics analytics;
  SurfaceOperation copyWith({
    SurfaceOperationPreview? preview,
    SurfaceOperationStatus? status,
    Duration? executionTime,
    String? undoToken,
    String? redoToken,
    String? diagnostic,
    SurfaceOperationValidation? validation,
    ShapeHandle? resultSurface,
    SurfaceOperationAnalytics? analytics,
  }) => SurfaceOperation(
    id: id,
    type: type,
    targetPatch: targetPatch,
    targetSurface: targetSurface,
    constraints: constraints,
    parameters: parameters,
    preview: preview ?? this.preview,
    status: status ?? this.status,
    createdAt: createdAt,
    executionTime: executionTime ?? this.executionTime,
    undoToken: undoToken ?? this.undoToken,
    redoToken: redoToken ?? this.redoToken,
    diagnostic: diagnostic ?? this.diagnostic,
    validation: validation ?? this.validation,
    resultSurface: resultSurface ?? this.resultSurface,
    analytics: analytics ?? this.analytics,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'targetPatch': targetPatch.id,
    'targetSurface': targetSurface.toJson(),
    'constraints': constraints.map((e) => e.toJson()).toList(),
    'parameters': parameters,
    'preview': preview?.toJson(),
    'status': status.name,
    'executionMicros': executionTime.inMicroseconds,
    'undoToken': undoToken,
    'redoToken': redoToken,
    'validation': validation?.toJson(),
    'analytics': analytics.toJson(),
    'resultSurface': resultSurface?.toJson(),
    'diagnostic': diagnostic,
    'createdAt': createdAt.toIso8601String(),
  };
}

class SurfaceOperationAdvice {
  const SurfaceOperationAdvice(this.operationId, this.message, this.suggestion);
  final String operationId, message, suggestion;
  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'message': message,
    'suggestion': suggestion,
    'consultative': true,
    'automaticAction': false,
  };
}
