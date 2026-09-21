import '../geometric_kernel/geometry/vectors.dart';
import 'plane_axis_intersection_point.dart';

enum AlignmentCoordinateSystemOriginKind { referencePoint, manual, viewport }

/// Durable local coordinate system derived from three reference snapshots.
///
/// `xAxis × yAxis = zAxis`. Axes are unit directions in world space; only the
/// origin has length units (millimetres).
final class AlignmentCoordinateSystem {
  const AlignmentCoordinateSystem({
    required this.origin,
    required this.xAxis,
    required this.yAxis,
    required this.zAxis,
    required this.plane,
    required this.axis,
    required this.originKind,
    this.point,
    this.angularTolerance = angularToleranceDefault,
  });

  static const dataKey = 'alignmentCoordinateSystem';
  static const schema = 'flcad.alignment-coordinate-system';
  static const version = 1;
  static const angularToleranceDefault = 1e-10;

  final Vector3 origin;
  final Vector3 xAxis;
  final Vector3 yAxis;
  final Vector3 zAxis;
  final ReferenceParentIdentity plane;
  final ReferenceParentIdentity axis;
  final AlignmentCoordinateSystemOriginKind originKind;
  final ReferenceParentIdentity? point;
  final double angularTolerance;

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'mode': 'snapshot',
    'originSource': originKind.name,
    'frame': {
      'space': 'world',
      'origin': origin.toJson(),
      'xAxis': xAxis.toJson(),
      'yAxis': yAxis.toJson(),
      'zAxis': zAxis.toJson(),
      'handedness': 'right',
    },
    'parents': {
      'plane': plane.toJson(),
      'axis': axis.toJson(),
      if (point case final value?) 'point': value.toJson(),
    },
    'tolerances': {'angular': angularTolerance},
  };

  factory AlignmentCoordinateSystem.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schema',
      'version',
      'mode',
      'originSource',
      'frame',
      'parents',
      'tolerances',
    };
    if (json.length != keys.length ||
        json.keys.toSet().difference(keys).isNotEmpty ||
        json['schema'] != schema ||
        json['version'] != version ||
        json['mode'] != 'snapshot' ||
        json['originSource'] is! String ||
        json['frame'] is! Map ||
        json['parents'] is! Map ||
        json['tolerances'] is! Map) {
      throw const FormatException('Invalid alignment coordinate system');
    }
    final frame = Map<String, dynamic>.from(json['frame'] as Map);
    final parents = Map<String, dynamic>.from(json['parents'] as Map);
    final tolerances = Map<String, dynamic>.from(json['tolerances'] as Map);
    if (frame.length != 6 ||
        frame['space'] != 'world' ||
        frame['handedness'] != 'right' ||
        (parents.length != 2 && parents.length != 3) ||
        parents.keys.toSet().difference(const {
          'plane',
          'axis',
          'point',
        }).isNotEmpty ||
        parents['plane'] is! Map ||
        parents['axis'] is! Map ||
        tolerances.length != 1 ||
        tolerances['angular'] is! num ||
        !(tolerances['angular'] as num).isFinite ||
        (tolerances['angular'] as num) <= 0) {
      throw const FormatException(
        'Invalid alignment coordinate system contract',
      );
    }
    final originKind = AlignmentCoordinateSystemOriginKind.values
        .where((value) => value.name == json['originSource'])
        .firstOrNull;
    final rawPoint = parents['point'];
    if (originKind == null ||
        (originKind == AlignmentCoordinateSystemOriginKind.referencePoint) !=
            (rawPoint is Map)) {
      throw const FormatException('Invalid alignment origin source');
    }
    final result = AlignmentCoordinateSystem(
      origin: _vector(frame['origin']),
      xAxis: _unitVector(frame['xAxis']),
      yAxis: _unitVector(frame['yAxis']),
      zAxis: _unitVector(frame['zAxis']),
      plane: ReferenceParentIdentity.fromJson(
        Map<String, dynamic>.from(parents['plane'] as Map),
      ),
      axis: ReferenceParentIdentity.fromJson(
        Map<String, dynamic>.from(parents['axis'] as Map),
      ),
      originKind: originKind,
      point: rawPoint is Map
          ? ReferenceParentIdentity.fromJson(
              Map<String, dynamic>.from(rawPoint),
            )
          : null,
      angularTolerance: (tolerances['angular'] as num).toDouble(),
    );
    if ((result.xAxis.cross(result.yAxis) - result.zAxis).length >
            result.angularTolerance ||
        result.xAxis.dot(result.yAxis).abs() > result.angularTolerance ||
        result.yAxis.dot(result.zAxis).abs() > result.angularTolerance ||
        result.zAxis.dot(result.xAxis).abs() > result.angularTolerance) {
      throw const FormatException(
        'Alignment coordinate system is not right-handed',
      );
    }
    return result;
  }

  static Vector3 _vector(Object? value) {
    if (value is! List ||
        value.length != 3 ||
        value.any((component) => component is! num || !component.isFinite)) {
      throw const FormatException('Invalid alignment coordinate value');
    }
    return Vector3(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
      (value[2] as num).toDouble(),
    );
  }

  static Vector3 _unitVector(Object? value) {
    final vector = _vector(value);
    if ((vector.length - 1).abs() > angularToleranceDefault) {
      throw const FormatException('Alignment axis must be normalized');
    }
    return vector;
  }
}
