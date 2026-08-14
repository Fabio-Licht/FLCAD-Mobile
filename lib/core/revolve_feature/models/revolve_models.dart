import '../../cad_kernel/models/kernel_models.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../../utils/id_generator.dart';

enum RevolveType {
  boss,
  cut,
  thin,
  surface,
  partial,
  full,
  symmetric,
  twoDirections,
  upToFace,
  upToPlane,
  upToVertex,
  mergeResult,
  newBody,
  multiProfile,
}

enum RevolveStatus {
  prepared,
  previewed,
  executing,
  success,
  kernelUnavailable,
  unsupportedOperation,
  invalid,
  failed,
  suppressed,
  rolledBack,
}

enum RevolveAxisKind { construction, edge, datum, reference }

class RevolveAxis {
  RevolveAxis({
    required this.origin,
    required this.direction,
    this.kind = RevolveAxisKind.datum,
    this.referenceId,
    this.reverse = false,
  });
  SketchVector origin, direction;
  RevolveAxisKind kind;
  String? referenceId;
  bool reverse;
  Map<String, dynamic> toJson() => {
    'origin': origin.toJson(),
    'direction': direction.toJson(),
    'kind': kind.name,
    'referenceId': referenceId,
    'reverse': reverse,
  };
}

class RevolveParameters {
  RevolveParameters({
    this.type = RevolveType.full,
    this.angle = 360,
    this.secondAngle = 0,
    this.reverse = false,
    this.merge = false,
    this.thickness = 0,
    this.bodyTarget,
    this.faceReference,
    this.planeReference,
    this.vertexReference,
  });
  RevolveType type;
  double angle, secondAngle, thickness;
  bool reverse, merge;
  String? bodyTarget, faceReference, planeReference, vertexReference;
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'angle': angle,
    'secondAngle': secondAngle,
    'reverse': reverse,
    'merge': merge,
    'thickness': thickness,
    'bodyTarget': bodyTarget,
    'faceReference': faceReference,
    'planeReference': planeReference,
    'vertexReference': vertexReference,
  };
}

class RevolveInput {
  RevolveInput({
    required this.sketchId,
    required List<String> profileIds,
    required this.axis,
    this.kernelProfile,
    this.multipleRegions = false,
    this.nestedRegions = false,
  }) : profileIds = List.of(profileIds);
  final String sketchId;
  final List<String> profileIds;
  RevolveAxis axis;
  final ShapeHandle? kernelProfile;
  final bool multipleRegions, nestedRegions;
}

class RevolveFeature {
  RevolveFeature({
    required this.input,
    required this.parameters,
    String? id,
    DateTime? timestamp,
    this.owner = 'local',
  }) : id = id ?? 'revolve:${IdGenerator.generate()}',
       timestamp = timestamp ?? DateTime.now().toUtc();
  final String id, owner;
  final RevolveInput input;
  final RevolveParameters parameters;
  final DateTime timestamp;
  int version = 1;
  RevolveStatus status = RevolveStatus.prepared;
  ShapeHandle? output;
  final List<String> diagnostics = [], history = [], dependencies = [];
  String? platformFeatureId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sketchId': input.sketchId,
    'profileIds': input.profileIds,
    'axis': input.axis.toJson(),
    'kernelProfile': input.kernelProfile?.toJson(),
    'parameters': parameters.toJson(),
    'owner': owner,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'status': status.name,
    'output': output?.toJson(),
    'diagnostics': diagnostics,
    'history': history,
    'dependencies': dependencies,
    'platformFeatureId': platformFeatureId,
  };
}

class RevolveExecutionResult {
  const RevolveExecutionResult(
    this.status, {
    this.shape,
    this.diagnostics = const [],
  });
  final RevolveStatus status;
  final ShapeHandle? shape;
  final List<String> diagnostics;
  bool get success => status == RevolveStatus.success && shape != null;
}
