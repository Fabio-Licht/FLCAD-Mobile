abstract final class InspectorValueFormatter {
  static const basicCoordinatePrecision = 3;
  static const _zeroThreshold = 0.0005;

  static String coordinateMm(Iterable<num> coordinates) {
    final values = coordinates.toList(growable: false);
    if (values.length != 3 || values.any((value) => !value.isFinite)) {
      throw const FormatException('Invalid Inspector coordinate');
    }
    String component(num value) {
      final number = value.toDouble().abs() < _zeroThreshold
          ? 0.0
          : value.toDouble();
      return number.toStringAsFixed(basicCoordinatePrecision);
    }

    return '[${values.map(component).join(', ')}] mm';
  }
}
