import 'dart:math' as math;
import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../models/professional_recognition_models.dart';

class PatternRecognitionEngine {
  const PatternRecognitionEngine();
  List<RecognizedPattern> recognize(List<ProfessionalPrimitive> primitives) {
    final cylinders = primitives
        .where((p) => p.recognition.winner.type == PrimitiveType.cylinder)
        .toList();
    if (cylinders.length < 3) return const [];
    final centers = cylinders
        .map((p) => _origin(p.recognition.winner))
        .whereType<Vector3>()
        .toList();
    if (centers.length < 3) return const [];
    final direction = (centers[1] - centers[0]).normalized,
        lineErrors = centers
            .map((c) => (c - centers[0]).cross(direction).length)
            .toList(),
        span = math.max(
          centers.map((c) => c.distanceTo(centers[0])).reduce(math.max),
          1e-12,
        ),
        confidence =
            1 /
            (1 + lineErrors.reduce((a, b) => a + b) / lineErrors.length / span);
    if (confidence < .8) return const [];
    final projections =
            centers.map((c) => (c - centers[0]).dot(direction)).toList()
              ..sort(),
        gaps = List.generate(
          projections.length - 1,
          (i) => projections[i + 1] - projections[i],
        ),
        spacing = gaps.reduce((a, b) => a + b) / gaps.length;
    return [
      RecognizedPattern(
        id: 'pattern:linear:${cylinders.first.recognition.id}',
        kind: 'linear',
        memberIds: cylinders.map((e) => e.recognition.id).toList(),
        confidence: confidence,
        explanation: 'Centros cilíndricos alinhados com espaçamento analisado.',
        axis: direction,
        spacing: spacing,
      ),
    ];
  }

  Vector3? _origin(RecognitionCandidate c) {
    final raw = c.parameters['origin'];
    return raw is List
        ? Vector3(
            (raw[0] as num).toDouble(),
            (raw[1] as num).toDouble(),
            (raw[2] as num).toDouble(),
          )
        : null;
  }
}
