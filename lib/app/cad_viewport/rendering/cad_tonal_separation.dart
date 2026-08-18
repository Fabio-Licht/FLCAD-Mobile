import 'dart:math' as math;
import 'dart:ui';

/// RENDER-001 — continuous, geometry-first tonal response.
abstract final class CadTonalSeparation {
  static Color shade(Color base, double signal, {double alpha = 1}) {
    final x = signal.clamp(0.0, 1.0);
    final smooth = x * x * (3 - 2 * x);
    final separated = math.pow(smooth, .82).toDouble();
    final shadow = Color.lerp(const Color(0xff09131d), base, .34)!;
    final light = Color.lerp(base, const Color(0xffe8f1f5), .28)!;
    return Color.lerp(
      shadow,
      light,
      .08 + .88 * separated,
    )!.withValues(alpha: alpha.clamp(0.0, 1.0));
  }
}
