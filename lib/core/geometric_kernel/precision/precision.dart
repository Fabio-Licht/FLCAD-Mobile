import 'dart:math' as math;

enum LengthUnit { millimeter, centimeter, meter, inch }

enum AngleUnit { degree, radian }

class Tolerance {
  const Tolerance({
    this.absolute = 1e-9,
    this.relative = 1e-9,
    this.angular = 1e-9,
  });
  final double absolute, relative, angular;
  bool close(double a, double b) {
    final scale = math.max(a.abs(), b.abs());
    return (a - b).abs() <= math.max(absolute, relative * scale);
  }
}

class PrecisionContext {
  const PrecisionContext({
    this.tolerance = const Tolerance(),
    this.lengthUnit = LengthUnit.millimeter,
    this.angleUnit = AngleUnit.radian,
    this.displayDecimals = 6,
  });
  final Tolerance tolerance;
  final LengthUnit lengthUnit;
  final AngleUnit angleUnit;
  final int displayDecimals;
  double adaptiveEpsilon(Iterable<double> values) {
    final scale = values.fold<double>(1, (a, b) => math.max(a, b.abs()));
    return math.max(tolerance.absolute, tolerance.relative * scale);
  }
}

class UnitConverter {
  const UnitConverter();
  static const _mm = {
    LengthUnit.millimeter: 1.0,
    LengthUnit.centimeter: 10.0,
    LengthUnit.meter: 1000.0,
    LengthUnit.inch: 25.4,
  };
  double length(double value, LengthUnit from, LengthUnit to) =>
      value * _mm[from]! / _mm[to]!;
  double angle(double value, AngleUnit from, AngleUnit to) => from == to
      ? value
      : from == AngleUnit.degree
      ? value * math.pi / 180
      : value * 180 / math.pi;
}
