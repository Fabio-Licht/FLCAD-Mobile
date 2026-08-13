import 'dart:math' as math;

import '../constraints/reference_constraint.dart';
import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

class ConstraintValidationResult {
  const ConstraintValidationResult(this.satisfied, this.error, this.message);
  final bool satisfied;
  final double error;
  final String message;
}

class ReferenceConstraintValidator {
  const ReferenceConstraintValidator({this.tolerance = 1e-6});
  final double tolerance;

  ConstraintValidationResult validate(
    ReferenceConstraint constraint,
    Map<String, ReferenceEntity> references,
  ) {
    if (!constraint.enabled) {
      return const ConstraintValidationResult(true, 0, 'disabled');
    }
    final entities = constraint.referenceIds
        .map((id) => references[id])
        .toList();
    if (entities.any((e) => e == null)) {
      return const ConstraintValidationResult(
        false,
        double.infinity,
        'missing reference',
      );
    }
    final a = entities[0]!.geometry, b = entities[1]!.geometry;
    final da = _direction(a), db = _direction(b);
    double error;
    switch (constraint.type) {
      case ReferenceConstraintType.parallel:
        error = da.cross(db).length;
      case ReferenceConstraintType.perpendicular:
        error = da.dot(db).abs();
      case ReferenceConstraintType.coincident:
      case ReferenceConstraintType.concentric:
        error = (_origin(a) - _origin(b)).length;
      case ReferenceConstraintType.fixedDistance:
        error =
            ((_origin(a) - _origin(b)).length -
                    (constraint.parameters['distance'] ?? 0))
                .abs();
      case ReferenceConstraintType.fixedAngle:
        final angle = math.acos(da.dot(db).clamp(-1, 1));
        error = (angle - (constraint.parameters['angle'] ?? 0)).abs();
      case ReferenceConstraintType.tangent:
        return const ConstraintValidationResult(
          false,
          double.infinity,
          'requires a surface adapter',
        );
    }
    return ConstraintValidationResult(
      error <= tolerance,
      error,
      error <= tolerance ? 'satisfied' : 'outside tolerance',
    );
  }

  dynamic _origin(ReferenceGeometry g) => switch (g) {
    PlaneGeometry v => v.origin,
    AxisGeometry v => v.origin,
    PointGeometry v => v.position,
    CurveGeometry v => v.points.first,
    CoordinateSystemGeometry v => v.origin,
  };

  dynamic _direction(ReferenceGeometry g) => switch (g) {
    PlaneGeometry v => v.normal,
    AxisGeometry v => v.direction,
    CurveGeometry v => (v.points.last - v.points.first).normalized,
    CoordinateSystemGeometry v => v.xAxis,
    PointGeometry _ => throw ArgumentError('Point has no direction'),
  };
}
