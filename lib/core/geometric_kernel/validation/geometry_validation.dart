import '../geometry/primitives.dart';
import '../geometry/vectors.dart';
import '../precision/precision.dart';

enum GeometryIssueSeverity { warning, error }

class GeometryIssue {
  const GeometryIssue(this.code, this.message, this.severity);
  final String code, message;
  final GeometryIssueSeverity severity;
}

class GeometryValidationResult {
  const GeometryValidationResult(this.issues);
  final List<GeometryIssue> issues;
  bool get isValid =>
      issues.every((i) => i.severity != GeometryIssueSeverity.error);
}

class GeometryValidator {
  const GeometryValidator([this.precision = const PrecisionContext()]);
  final PrecisionContext precision;
  GeometryValidationResult vector(Vector3 value) {
    final issues = <GeometryIssue>[];
    if (!value.x.isFinite || !value.y.isFinite || !value.z.isFinite) {
      issues.add(
        const GeometryIssue(
          'GK_NON_FINITE',
          'Vector contains a non-finite component',
          GeometryIssueSeverity.error,
        ),
      );
    }
    return GeometryValidationResult(issues);
  }

  GeometryValidationResult line(Line3 value) {
    final issues = [
      ...vector(value.origin).issues,
      ...vector(value.direction).issues,
    ];
    if (value.direction.length <= precision.tolerance.absolute) {
      issues.add(
        const GeometryIssue(
          'GK_ZERO_DIRECTION',
          'Line direction is degenerate',
          GeometryIssueSeverity.error,
        ),
      );
    }
    return GeometryValidationResult(issues);
  }

  GeometryValidationResult triangle(Triangle3 value) {
    final issues = [
      ...vector(value.a).issues,
      ...vector(value.b).issues,
      ...vector(value.c).issues,
    ];
    if (value.area <=
        precision.tolerance.absolute * precision.tolerance.absolute) {
      issues.add(
        const GeometryIssue(
          'GK_DEGENERATE_TRIANGLE',
          'Triangle area is below tolerance',
          GeometryIssueSeverity.error,
        ),
      );
    }
    return GeometryValidationResult(issues);
  }
}
