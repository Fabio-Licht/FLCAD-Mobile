import 'dart:math' as math;
import '../../sketch_engine/models/sketch_models.dart';
import '../models/revolve_models.dart';

enum AxisDiagnosticType { missing, invalid, coincident, crossingProfile }

class AxisDiagnostic {
  const AxisDiagnostic(this.type, this.message);
  final AxisDiagnosticType type;
  final String message;
}

class AxisAnalysis {
  const AxisAnalysis(
    this.valid,
    this.normalizedDirection,
    this.orientation,
    this.diagnostics,
  );
  final bool valid;
  final SketchVector normalizedDirection;
  final String orientation;
  final List<AxisDiagnostic> diagnostics;
}

class RevolveAxisEngine {
  const RevolveAxisEngine();
  AxisAnalysis analyze(RevolveAxis? axis) {
    if (axis == null) {
      return const AxisAnalysis(false, SketchVector(0, 0, 0), 'missing', [
        AxisDiagnostic(AxisDiagnosticType.missing, 'Missing axis'),
      ]);
    }
    final d = axis.direction,
        length = math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z);
    if (length == 0) {
      return const AxisAnalysis(false, SketchVector(0, 0, 0), 'invalid', [
        AxisDiagnostic(
          AxisDiagnosticType.invalid,
          'Axis direction cannot be zero',
        ),
      ]);
    }
    final n = SketchVector(d.x / length, d.y / length, d.z / length);
    return AxisAnalysis(
      true,
      axis.reverse ? n.scale(-1) : n,
      n.z.abs() > .9 ? 'normal-to-sketch' : 'in-sketch',
      const [],
    );
  }

  void flip(RevolveAxis axis) => axis.reverse = !axis.reverse;
}
