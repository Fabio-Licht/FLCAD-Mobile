import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum MorphTool { move, push, pull, relax, fair, match, custom }

enum AnchorType { fixed, soft, boundary, surface, curve, point, multi }

enum FalloffType { linear, smooth, gaussian, bell, customCurve }

enum MorphStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

class MorphAnchor {
  const MorphAnchor({
    required this.id,
    required this.type,
    required this.targetId,
    required this.position,
    this.strength = 1,
  });
  final String id, targetId;
  final AnchorType type;
  final List<double> position;
  final double strength;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'target': targetId,
    'position': position,
    'strength': strength,
  };
}

class MorphConstraintGroup {
  const MorphConstraintGroup(this.id, this.name, this.constraints);
  final String id, name;
  final List<SurfaceConstraint> constraints;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'constraints': constraints.map((e) => e.toJson()).toList(),
  };
}

class InfluenceRegion {
  const InfluenceRegion({
    required this.radius,
    required this.falloff,
    required this.weights,
    this.customCurve = const [],
  });
  final double radius;
  final FalloffType falloff;
  final Map<String, double> weights;
  final List<double> customCurve;
  Map<String, dynamic> toJson() => {
    'radius': radius,
    'falloff': falloff.name,
    'weights': weights,
    'customCurve': customCurve,
  };
}

class MorphPreview {
  const MorphPreview({
    required this.id,
    required this.originalSurfaceId,
    required this.affectedPatches,
    required this.affectedBoundaries,
    required this.influence,
    required this.createdAt,
  });
  final String id, originalSurfaceId;
  final List<String> affectedPatches, affectedBoundaries;
  final InfluenceRegion influence;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'originalSurfaceId': originalSurfaceId,
    'affectedPatches': affectedPatches,
    'affectedBoundaries': affectedBoundaries,
    'influence': influence.toJson(),
    'realTime': true,
    'geometryModified': false,
    'createdAt': createdAt.toIso8601String(),
  };
}

class MorphValidation {
  const MorphValidation(
    this.valid,
    this.topology,
    this.continuity,
    this.quality,
    this.patches,
    this.boundaries,
    this.conflicts,
    this.errors,
  );
  final bool valid, topology, continuity, quality, patches, boundaries;
  final List<String> conflicts, errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'topology': topology,
    'continuity': continuity,
    'quality': quality,
    'patches': patches,
    'boundaries': boundaries,
    'constraintConflicts': conflicts,
    'errors': errors,
  };
}

class MorphAnalytics {
  const MorphAnalytics({
    required this.executionTime,
    required this.anchorCount,
    required this.influencedRegions,
    required this.rollbacks,
    required this.commits,
    required this.cancellations,
  });
  final Duration executionTime;
  final int anchorCount, influencedRegions, rollbacks, commits, cancellations;
  Map<String, dynamic> toJson() => {
    'executionMicros': executionTime.inMicroseconds,
    'anchors': anchorCount,
    'influencedRegions': influencedRegions,
    'rollbacks': rollbacks,
    'commits': commits,
    'cancellations': cancellations,
  };
}

class MorphAdvice {
  const MorphAdvice(this.message);
  final String message;
  Map<String, dynamic> toJson() => {
    'message': message,
    'consultative': true,
    'automaticAction': false,
  };
}

class MorphSession {
  const MorphSession({
    required this.id,
    required this.tool,
    required this.targetPatch,
    required this.anchors,
    required this.constraintGroups,
    required this.radius,
    required this.falloff,
    required this.parameters,
    required this.status,
    required this.history,
    required this.analytics,
    required this.advice,
    required this.createdAt,
    this.preview,
    this.validation,
    this.surfaceOperationId,
    this.liveReconstructionId,
    this.diagnostic,
  });
  final String id;
  final MorphTool tool;
  final PatchEntity targetPatch;
  final List<MorphAnchor> anchors;
  final List<MorphConstraintGroup> constraintGroups;
  final double radius;
  final FalloffType falloff;
  final Map<String, dynamic> parameters;
  final MorphStatus status;
  final MorphPreview? preview;
  final MorphValidation? validation;
  final String? surfaceOperationId, liveReconstructionId, diagnostic;
  final List<Map<String, dynamic>> history;
  final MorphAnalytics analytics;
  final List<MorphAdvice> advice;
  final DateTime createdAt;
  MorphSession copyWith({
    MorphStatus? status,
    MorphPreview? preview,
    MorphValidation? validation,
    String? surfaceOperationId,
    String? liveReconstructionId,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
    MorphAnalytics? analytics,
    List<MorphAdvice>? advice,
  }) => MorphSession(
    id: id,
    tool: tool,
    targetPatch: targetPatch,
    anchors: anchors,
    constraintGroups: constraintGroups,
    radius: radius,
    falloff: falloff,
    parameters: parameters,
    status: status ?? this.status,
    preview: preview ?? this.preview,
    validation: validation ?? this.validation,
    surfaceOperationId: surfaceOperationId ?? this.surfaceOperationId,
    liveReconstructionId: liveReconstructionId ?? this.liveReconstructionId,
    diagnostic: diagnostic ?? this.diagnostic,
    history: history ?? this.history,
    analytics: analytics ?? this.analytics,
    advice: advice ?? this.advice,
    createdAt: createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'tool': tool.name,
    'targetPatch': targetPatch.id,
    'anchors': anchors.map((e) => e.toJson()).toList(),
    'constraintGroups': constraintGroups.map((e) => e.toJson()).toList(),
    'influenceRadius': radius,
    'falloff': falloff.name,
    'parameters': parameters,
    'status': status.name,
    'preview': preview?.toJson(),
    'validation': validation?.toJson(),
    'surfaceOperationId': surfaceOperationId,
    'liveReconstructionId': liveReconstructionId,
    'diagnostic': diagnostic,
    'history': history,
    'analytics': analytics.toJson(),
    'advisor': advice.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
