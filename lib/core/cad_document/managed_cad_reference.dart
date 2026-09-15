import '../geometric_kernel/geometry/vectors.dart';

enum ManagedCadReferenceKind { plane }

/// Durable definition of a reference extracted from immutable managed B-Rep.
/// Native custody identifiers and presentation-triangle identifiers are never
/// part of this contract.
final class ManagedCadReference {
  const ManagedCadReference({
    required this.kind,
    required this.sourceEntityId,
    required this.sourceFormat,
    required this.sourceShapeSha256,
    required this.faceIndex,
    required this.origin,
    required this.normal,
    required this.xDirection,
  });

  static const dataKey = 'managedCadReference';
  static const schema = 'flcad.managed-cad-reference';
  static const version = 1;

  final ManagedCadReferenceKind kind;
  final String sourceEntityId;
  final String sourceFormat;
  final String sourceShapeSha256;
  final int faceIndex;
  final Vector3 origin;
  final Vector3 normal;
  final Vector3 xDirection;

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'kind': kind.name,
    'sourceEntityId': sourceEntityId,
    'sourceFormat': sourceFormat,
    'sourceShapeSha256': sourceShapeSha256,
    'subshape': {'kind': 'face', 'index': faceIndex},
    'geometry': {
      'space': 'world',
      'origin': origin.toJson(),
      'normal': normal.toJson(),
      'xDirection': xDirection.toJson(),
    },
  };

  factory ManagedCadReference.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schema',
      'version',
      'kind',
      'sourceEntityId',
      'sourceFormat',
      'sourceShapeSha256',
      'subshape',
      'geometry',
    };
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        json.length != keys.length ||
        json['schema'] != schema ||
        json['version'] != version ||
        json['kind'] != ManagedCadReferenceKind.plane.name ||
        json['sourceEntityId'] is! String ||
        (json['sourceEntityId'] as String).isEmpty ||
        !{'step', 'brep'}.contains(json['sourceFormat']) ||
        json['sourceShapeSha256'] is! String ||
        !RegExp(
          r'^[0-9a-f]{64}$',
        ).hasMatch(json['sourceShapeSha256'] as String) ||
        json['subshape'] is! Map ||
        json['geometry'] is! Map) {
      throw const FormatException('Invalid managed CAD reference');
    }
    final subshape = Map<String, dynamic>.from(json['subshape'] as Map);
    final geometry = Map<String, dynamic>.from(json['geometry'] as Map);
    if (subshape.length != 2 ||
        subshape['kind'] != 'face' ||
        subshape['index'] is! int ||
        (subshape['index'] as int) <= 0 ||
        geometry.keys.toSet().difference(const {
          'space',
          'origin',
          'normal',
          'xDirection',
        }).isNotEmpty ||
        geometry.length != 4 ||
        geometry['space'] != 'world') {
      throw const FormatException('Invalid managed CAD reference topology');
    }
    final origin = _vector(geometry['origin']);
    final normal = _vector(geometry['normal']);
    final xDirection = _vector(geometry['xDirection']);
    if (normal.length <= 1e-12 ||
        xDirection.length <= 1e-12 ||
        normal.normalized.dot(xDirection.normalized).abs() > 1e-8) {
      throw const FormatException('Invalid managed CAD reference geometry');
    }
    return ManagedCadReference(
      kind: ManagedCadReferenceKind.plane,
      sourceEntityId: json['sourceEntityId'] as String,
      sourceFormat: json['sourceFormat'] as String,
      sourceShapeSha256: json['sourceShapeSha256'] as String,
      faceIndex: subshape['index'] as int,
      origin: origin,
      normal: normal.normalized,
      xDirection: xDirection.normalized,
    );
  }

  static Vector3 _vector(Object? value) {
    if (value is! List ||
        value.length != 3 ||
        value.any((component) => component is! num || !component.isFinite)) {
      throw const FormatException('Invalid managed CAD reference vector');
    }
    return Vector3(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
      (value[2] as num).toDouble(),
    );
  }
}
