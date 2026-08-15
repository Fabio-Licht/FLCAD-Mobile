import 'dart:math' as math;

import '../../geometric_recognition/models/recognition_models.dart';
import '../models/primitive_intelligence_models.dart';

class AlignmentIntelligence {
  const AlignmentIntelligence();
  AlignmentSuggestion analyze(PrimitiveObservation value) {
    final current =
        value.vectors['normal'] ??
        value.vectors['axis'] ??
        value.vectors['center'];
    if (current == null || current.length != 3) {
      return AlignmentSuggestion(
        currentOrientation: const [0, 0, 0],
        suggestedOrientation: 'undetermined',
        angularDeviation: const {'X': 90, 'Y': 90, 'Z': 90},
        angularError: 90,
        confidence: 0,
        justification: 'No orientation vector was supplied by recognition.',
      );
    }
    final normalized = _normalize(current);
    final deviations = {
      'X': _angle(normalized, const [1, 0, 0]),
      'Y': _angle(normalized, const [0, 1, 0]),
      'Z': _angle(normalized, const [0, 0, 1]),
    };
    final nearest = deviations.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    final suggested = value.type == PrimitiveType.plane
        ? 'parallel to ${switch (nearest.key) {
            'X' => 'YZ',
            'Y' => 'XZ',
            _ => 'XY',
          }} plane'
        : value.type == PrimitiveType.sphere
        ? 'center direction aligned to ${nearest.key} axis'
        : 'axis aligned to ${nearest.key} axis';
    return AlignmentSuggestion(
      currentOrientation: normalized,
      suggestedOrientation: suggested,
      angularDeviation: deviations,
      angularError: nearest.value,
      confidence: value.recognitionConfidence,
      justification:
          'Nearest principal orientation calculated from absolute dot products; no transform was applied.',
    );
  }

  List<double> _normalize(List<double> value) {
    final length = math.sqrt(
      value.fold<double>(0, (sum, item) => sum + item * item),
    );
    if (length == 0) return const [0, 0, 0];
    return value.map((item) => item / length).toList(growable: false);
  }

  double _angle(List<double> a, List<double> b) {
    final dot = (a[0] * b[0] + a[1] * b[1] + a[2] * b[2]).abs().clamp(0, 1);
    return math.acos(dot) * 180 / math.pi;
  }
}
