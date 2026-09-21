import '../geometric_kernel/geometry/vectors.dart';

final class ReferenceParentIdentity {
  const ReferenceParentIdentity({
    required this.entityId,
    required this.identitySha256,
  });

  final String entityId;
  final String identitySha256;

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'identitySha256': identitySha256,
  };

  factory ReferenceParentIdentity.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        json['entityId'] is! String ||
        (json['entityId'] as String).isEmpty ||
        json['identitySha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(json['identitySha256'] as String)) {
      throw const FormatException('Invalid reference parent identity');
    }
    return ReferenceParentIdentity(
      entityId: json['entityId'] as String,
      identitySha256: json['identitySha256'] as String,
    );
  }
}

/// Durable snapshot created from one plane and one axis reference.
///
/// The point never recomputes automatically. Parent identities exist only to
/// report an explicit orphan/invalid state if either source disappears or its
/// defining geometry changes.
final class PlaneAxisIntersectionPoint {
  const PlaneAxisIntersectionPoint({
    required this.point,
    required this.plane,
    required this.axis,
    this.angularTolerance = angularToleranceDefault,
    this.linearTolerance = linearToleranceDefault,
  });

  static const dataKey = 'planeAxisIntersectionPoint';
  static const schema = 'flcad.plane-axis-intersection-point';
  static const version = 1;

  /// Absolute dot-product threshold for normalized plane normal/axis vectors.
  static const angularToleranceDefault = 1e-10;

  /// World-space tolerance in millimetres used to distinguish contained axes.
  static const linearToleranceDefault = 1e-9;

  final Vector3 point;
  final ReferenceParentIdentity plane;
  final ReferenceParentIdentity axis;
  final double angularTolerance;
  final double linearTolerance;

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'mode': 'snapshot',
    'geometry': {'space': 'world', 'point': point.toJson()},
    'parents': {'plane': plane.toJson(), 'axis': axis.toJson()},
    'tolerances': {'angular': angularTolerance, 'linearMm': linearTolerance},
  };

  factory PlaneAxisIntersectionPoint.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schema',
      'version',
      'mode',
      'geometry',
      'parents',
      'tolerances',
    };
    if (json.length != keys.length ||
        json.keys.toSet().difference(keys).isNotEmpty ||
        json['schema'] != schema ||
        json['version'] != version ||
        json['mode'] != 'snapshot' ||
        json['geometry'] is! Map ||
        json['parents'] is! Map ||
        json['tolerances'] is! Map) {
      throw const FormatException('Invalid plane-axis intersection point');
    }
    final geometry = Map<String, dynamic>.from(json['geometry'] as Map);
    final parents = Map<String, dynamic>.from(json['parents'] as Map);
    final tolerances = Map<String, dynamic>.from(json['tolerances'] as Map);
    if (geometry.length != 2 ||
        geometry['space'] != 'world' ||
        parents.length != 2 ||
        parents['plane'] is! Map ||
        parents['axis'] is! Map ||
        tolerances.length != 2 ||
        tolerances['angular'] is! num ||
        tolerances['linearMm'] is! num ||
        !(tolerances['angular'] as num).isFinite ||
        !(tolerances['linearMm'] as num).isFinite ||
        (tolerances['angular'] as num) <= 0 ||
        (tolerances['linearMm'] as num) <= 0) {
      throw const FormatException('Invalid plane-axis intersection contract');
    }
    return PlaneAxisIntersectionPoint(
      point: _vector(geometry['point']),
      plane: ReferenceParentIdentity.fromJson(
        Map<String, dynamic>.from(parents['plane'] as Map),
      ),
      axis: ReferenceParentIdentity.fromJson(
        Map<String, dynamic>.from(parents['axis'] as Map),
      ),
      angularTolerance: (tolerances['angular'] as num).toDouble(),
      linearTolerance: (tolerances['linearMm'] as num).toDouble(),
    );
  }

  static Vector3 _vector(Object? value) {
    if (value is! List ||
        value.length != 3 ||
        value.any((component) => component is! num || !component.isFinite)) {
      throw const FormatException('Invalid intersection point coordinate');
    }
    return Vector3(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
      (value[2] as num).toDouble(),
    );
  }
}
