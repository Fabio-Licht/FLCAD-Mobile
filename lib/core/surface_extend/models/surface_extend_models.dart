import '../../surface_morph/models/surface_morph_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';

enum ExtendType {
  distance,
  angle,
  vector,
  untilSurface,
  untilPlane,
  untilCurve,
  tangentG1,
  curvatureG2,
  manufacturing,
  draft,
  smart,
}

enum ExtendStatus {
  created,
  previewed,
  validated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

class ExtendAnalysis {
  const ExtendAnalysis({
    required this.distance,
    required this.angle,
    required this.direction,
    required this.affectedPatches,
    required this.affectedBoundaries,
    required this.predictedContinuity,
    required this.reflectionScore,
    required this.zebraScore,
    required this.tension,
    required this.twistRisk,
    required this.estimatedQuality,
    required this.selfIntersectionRisk,
  });
  final double distance,
      angle,
      reflectionScore,
      zebraScore,
      tension,
      twistRisk,
      estimatedQuality,
      selfIntersectionRisk;
  final List<double> direction;
  final List<String> affectedPatches, affectedBoundaries;
  final String predictedContinuity;
  Map<String, dynamic> toJson() => {
    'distance': distance,
    'angle': angle,
    'direction': direction,
    'affectedPatches': affectedPatches,
    'affectedBoundaries': affectedBoundaries,
    'predictedContinuity': predictedContinuity,
    'predictedReflection': reflectionScore,
    'predictedZebra': zebraScore,
    'predictedTension': tension,
    'predictedTwist': twistRisk,
    'estimatedQuality': estimatedQuality,
    'selfIntersectionRisk': selfIntersectionRisk,
    'geometryModified': false,
  };
}

class ExtendValidation {
  const ExtendValidation(
    this.valid,
    this.topology,
    this.continuity,
    this.reflection,
    this.zebra,
    this.draft,
    this.quality,
    this.twist,
    this.selfIntersection,
    this.constraints,
    this.errors,
  );
  final bool valid,
      topology,
      continuity,
      reflection,
      zebra,
      draft,
      quality,
      twist,
      selfIntersection,
      constraints;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'topology': topology,
    'continuity': continuity,
    'reflection': reflection,
    'zebra': zebra,
    'draft': draft,
    'quality': quality,
    'twist': twist,
    'selfIntersection': selfIntersection,
    'constraints': constraints,
    'errors': errors,
  };
}

class ExtendAdvice {
  const ExtendAdvice(this.message);
  final String message;
  Map<String, dynamic> toJson() => {
    'message': message,
    'consultative': true,
    'automaticAction': false,
  };
}

class ExtendSession {
  const ExtendSession({
    required this.id,
    required this.type,
    required this.patch,
    required this.boundaryId,
    required this.anchors,
    required this.parameters,
    required this.manufacturingIntent,
    required this.status,
    required this.history,
    required this.createdAt,
    this.analysis,
    this.validation,
    this.morphSessionId,
    this.diagnostic,
  });
  final String id, boundaryId, manufacturingIntent;
  final ExtendType type;
  final PatchEntity patch;
  final List<MorphAnchor> anchors;
  final Map<String, dynamic> parameters;
  final ExtendStatus status;
  final ExtendAnalysis? analysis;
  final ExtendValidation? validation;
  final String? morphSessionId, diagnostic;
  final List<Map<String, dynamic>> history;
  final DateTime createdAt;
  ExtendSession copyWith({
    ExtendStatus? status,
    ExtendAnalysis? analysis,
    ExtendValidation? validation,
    String? morphSessionId,
    String? diagnostic,
    List<Map<String, dynamic>>? history,
  }) => ExtendSession(
    id: id,
    type: type,
    patch: patch,
    boundaryId: boundaryId,
    anchors: anchors,
    parameters: parameters,
    manufacturingIntent: manufacturingIntent,
    status: status ?? this.status,
    analysis: analysis ?? this.analysis,
    validation: validation ?? this.validation,
    morphSessionId: morphSessionId ?? this.morphSessionId,
    diagnostic: diagnostic ?? this.diagnostic,
    history: history ?? this.history,
    createdAt: createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'patch': patch.id,
    'boundary': boundaryId,
    'anchors': anchors.map((e) => e.toJson()).toList(),
    'parameters': parameters,
    'manufacturingIntent': manufacturingIntent,
    'status': status.name,
    'analysis': analysis?.toJson(),
    'validation': validation?.toJson(),
    'morphSessionId': morphSessionId,
    'diagnostic': diagnostic,
    'history': history,
    'createdAt': createdAt.toIso8601String(),
  };
}
