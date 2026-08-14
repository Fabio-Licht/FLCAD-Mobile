import '../../cad_kernel/models/kernel_models.dart';
import '../../utils/id_generator.dart';

enum ReferenceType {
  datumPlane,
  datumAxis,
  datumPoint,
  coordinateSystem,
  constructionPlane,
  constructionAxis,
  constructionPoint,
  referenceCurve,
  referenceFrame,
  referenceGroup,
}

enum ReferenceMethod {
  offsetPlane,
  threePoints,
  planeDistance,
  parallelPlane,
  perpendicularPlane,
  midPlane,
  planeFromFace,
  twoPoints,
  cylinderAxis,
  coneAxis,
  planeIntersection,
  edgeAxis,
  vectorAxis,
  xyz,
  axisIntersection,
  curveIntersection,
  meshPick,
  edgeMidpoint,
  origin,
  planeAxis,
  importedSystem,
  group,
}

enum ReferenceStatus {
  prepared,
  previewed,
  executing,
  ready,
  kernelUnavailable,
  unsupportedOperation,
  invalid,
  failed,
  suppressed,
  frozen,
}

class ReferenceVector {
  const ReferenceVector(this.x, this.y, this.z);
  final double x, y, z;
  bool get finite => x.isFinite && y.isFinite && z.isFinite;
  bool get zero => x == 0 && y == 0 && z == 0;
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class ReferenceParameters {
  ReferenceParameters({
    this.origin = const ReferenceVector(0, 0, 0),
    this.direction = const ReferenceVector(0, 0, 1),
    this.xAxis = const ReferenceVector(1, 0, 0),
    this.yAxis = const ReferenceVector(0, 1, 0),
    this.offset = 0,
    this.distance = 0,
  });
  ReferenceVector origin, direction, xAxis, yAxis;
  double offset, distance;
  Map<String, dynamic> toJson() => {
    'origin': origin.toJson(),
    'direction': direction.toJson(),
    'xAxis': xAxis.toJson(),
    'yAxis': yAxis.toJson(),
    'offset': offset,
    'distance': distance,
  };
}

class ReferenceInput {
  ReferenceInput({
    this.referenceIds = const [],
    this.kernelReferences = const [],
  });
  final List<String> referenceIds;
  final List<ShapeHandle> kernelReferences;
  Map<String, dynamic> toJson() => {
    'referenceIds': referenceIds,
    'kernelReferences': kernelReferences.map((e) => e.toJson()).toList(),
  };
}

class ReferenceEntity {
  ReferenceEntity({
    required this.type,
    required this.method,
    required this.name,
    required this.input,
    required this.parameters,
    String? id,
  }) : id = id ?? 'reference:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id;
  final ReferenceType type;
  ReferenceMethod method;
  String name;
  final ReferenceInput input;
  final ReferenceParameters parameters;
  final DateTime timestamp;
  int version = 1, order = 0;
  bool visible = true, frozen = false;
  String? groupId;
  ReferenceStatus status = ReferenceStatus.prepared;
  ShapeHandle? output;
  final List<String> dependencies = [], diagnostics = [];
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'method': method.name,
    'name': name,
    'input': input.toJson(),
    'parameters': parameters.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'order': order,
    'visible': visible,
    'frozen': frozen,
    'groupId': groupId,
    'status': status.name,
    'output': output?.toJson(),
    'dependencies': dependencies,
    'diagnostics': diagnostics,
  };
}

class ReferenceExecutionResult {
  const ReferenceExecutionResult(
    this.status, {
    this.shape,
    this.diagnostics = const [],
  });
  final ReferenceStatus status;
  final ShapeHandle? shape;
  final List<String> diagnostics;
  bool get success => status == ReferenceStatus.ready && shape != null;
}
