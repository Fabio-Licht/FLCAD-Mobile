import 'dart:math' as math;

import '../../sketch_engine/models/sketch_models.dart';

/// Transient, screen-space acquisition of exact round Sketch coordinates.
/// The coarser magnet step stays about 50 pixels apart; the ordinary fine
/// grid remains unchanged. Release is wider than capture to avoid flicker.
class SketchCoordinateMagnet {
  double? lockedX;
  double? lockedY;

  void clear() {
    lockedX = null;
    lockedY = null;
  }

  SketchVector apply({
    required SketchVector pointer,
    required SketchVector candidate,
    required double worldPerPixel,
  }) {
    if (!worldPerPixel.isFinite || worldPerPixel <= 0) {
      clear();
      return candidate;
    }
    final step = _niceStep(worldPerPixel * 50);
    final capture = worldPerPixel * 10;
    final release = worldPerPixel * 16;
    lockedX = _acquire(pointer.x, lockedX, step, capture, release);
    lockedY = _acquire(pointer.y, lockedY, step, capture, release);
    return SketchVector(lockedX ?? candidate.x, lockedY ?? candidate.y);
  }

  double? _acquire(
    double coordinate,
    double? previous,
    double step,
    double capture,
    double release,
  ) {
    if (!coordinate.isFinite) return null;
    if (previous != null && (coordinate - previous).abs() <= release) {
      return previous;
    }
    final rounded = (coordinate / step).round() * step;
    final target = rounded == 0 ? 0.0 : rounded;
    return (coordinate - target).abs() <= capture ? target : null;
  }

  double _niceStep(double minimum) {
    final magnitude = math.pow(10, (math.log(minimum) / math.ln10).floor());
    final unit = magnitude.toDouble();
    final normalized = minimum / unit;
    final multiple = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 5
        ? 5.0
        : 10.0;
    return multiple * unit;
  }
}
