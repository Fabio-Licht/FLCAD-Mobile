import 'dart:math' as math;

import '../sketch_engine/models/sketch_models.dart';

enum SketchAssistantPrecision { high, medium, low }

extension SketchAssistantPrecisionContract on SketchAssistantPrecision {
  double get tolerance => switch (this) {
    SketchAssistantPrecision.high => .08,
    SketchAssistantPrecision.medium => .25,
    SketchAssistantPrecision.low => .6,
  };
}

enum SketchAssistantPrimitive { line, arc, circle }

class SketchAssistantSuggestion {
  const SketchAssistantSuggestion({
    required this.type,
    required this.sourceReferenceCurveId,
    required this.points,
    required this.confidence,
    this.center,
    this.radius,
    this.startAngle,
    this.endAngle,
  });

  final SketchAssistantPrimitive type;
  final String sourceReferenceCurveId;
  final List<SketchVector> points;
  final double confidence;
  final SketchVector? center;
  final double? radius, startAngle, endAngle;

  String get label => switch (type) {
    SketchAssistantPrimitive.line => 'Linha sugerida',
    SketchAssistantPrimitive.arc =>
      'Arco sugerido  R = ${radius!.toStringAsFixed(2)}',
    SketchAssistantPrimitive.circle =>
      'Círculo sugerido  Ø ${(radius! * 2).toStringAsFixed(2)}',
  };
}

class SketchAssistantReference {
  const SketchAssistantReference(this.id, this.segments);
  final String id;
  final List<(SketchVector, SketchVector)> segments;
}

/// Stateless recognizer. It never owns or persists suggestions and never
/// mutates either the Reference Curve or Sketch geometry.
class SketchAssistantEngine {
  const SketchAssistantEngine();

  SketchAssistantSuggestion? suggest({
    required SketchAssistantPrimitive requested,
    required SketchVector cursor,
    required Iterable<SketchAssistantReference> references,
    required SketchAssistantPrecision precision,
    SketchVector? anchor,
  }) {
    SketchAssistantSuggestion? best;
    for (final reference in references) {
      final candidate = switch (requested) {
        SketchAssistantPrimitive.line => _line(
          reference,
          cursor,
          anchor,
          precision.tolerance,
        ),
        SketchAssistantPrimitive.arc => _round(
          reference,
          cursor,
          precision.tolerance,
          false,
        ),
        SketchAssistantPrimitive.circle => _round(
          reference,
          cursor,
          precision.tolerance,
          true,
        ),
      };
      if (candidate != null &&
          (best == null || candidate.confidence > best.confidence)) {
        best = candidate;
      }
    }
    return best;
  }

  SketchAssistantSuggestion? _line(
    SketchAssistantReference reference,
    SketchVector cursor,
    SketchVector? anchor,
    double tolerance,
  ) {
    final nearby = reference.segments
        .where((s) => _segmentDistance(cursor, s.$1, s.$2) <= tolerance * 4)
        .toList();
    if (nearby.isEmpty) return null;
    nearby.sort(
      (a, b) => _segmentDistance(
        cursor,
        a.$1,
        a.$2,
      ).compareTo(_segmentDistance(cursor, b.$1, b.$2)),
    );
    final seed = nearby.first;
    final dx = seed.$2.x - seed.$1.x, dy = seed.$2.y - seed.$1.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 1e-9) return null;
    final ux = dx / length, uy = dy / length;
    final origin = anchor ?? seed.$1;
    final candidates = <SketchVector>[];
    for (final segment in nearby.take(24)) {
      candidates.addAll([segment.$1, segment.$2]);
    }
    var minT = double.infinity, maxT = -double.infinity, residual = 0.0;
    for (final p in candidates) {
      final px = p.x - origin.x, py = p.y - origin.y;
      final t = px * ux + py * uy;
      minT = math.min(minT, t);
      maxT = math.max(maxT, t);
      residual += (px * uy - py * ux).abs();
    }
    residual /= candidates.length;
    if (residual > tolerance) return null;
    final start =
        anchor ?? SketchVector(origin.x + ux * minT, origin.y + uy * minT);
    final projected = (cursor.x - start.x) * ux + (cursor.y - start.y) * uy;
    final extent = anchor == null ? maxT - minT : projected;
    final end = SketchVector(start.x + ux * extent, start.y + uy * extent);
    if (_length(end - start) <= tolerance) return null;
    return SketchAssistantSuggestion(
      type: SketchAssistantPrimitive.line,
      sourceReferenceCurveId: reference.id,
      points: [start, end],
      confidence: (1 - residual / tolerance).clamp(0.0, 1.0),
    );
  }

  SketchAssistantSuggestion? _round(
    SketchAssistantReference reference,
    SketchVector cursor,
    double tolerance,
    bool requireClosed,
  ) {
    final points = <SketchVector>[];
    for (final segment in reference.segments) {
      points.add(segment.$1);
      points.add(segment.$2);
    }
    final unique = <String, SketchVector>{
      for (final p in points)
        '${p.x.toStringAsFixed(6)}:${p.y.toStringAsFixed(6)}': p,
    }.values.toList();
    if (unique.length < 6) return null;
    final fit = _fitCircle(unique);
    if (fit == null || fit.$2 <= tolerance) return null;
    final center = fit.$1;
    final radius = fit.$2;
    final radialError =
        unique
            .map((p) => (_length(p - center) - radius).abs())
            .reduce((a, b) => a + b) /
        unique.length;
    if (radialError > tolerance) return null;
    final angles =
        unique.map((p) => math.atan2(p.y - center.y, p.x - center.x)).toList()
          ..sort();
    var largestGap = 0.0, gapIndex = 0;
    for (var i = 0; i < angles.length; i++) {
      final next = i + 1 < angles.length
          ? angles[i + 1]
          : angles.first + 2 * math.pi;
      if (next - angles[i] > largestGap) {
        largestGap = next - angles[i];
        gapIndex = i;
      }
    }
    final sweep = 2 * math.pi - largestGap;
    final closed = sweep >= 2 * math.pi - .25;
    if (requireClosed != closed) return null;
    if ((_length(cursor - center) - radius).abs() > tolerance * 5) {
      return null;
    }
    final start = angles[(gapIndex + 1) % angles.length];
    final end = start + sweep;
    return SketchAssistantSuggestion(
      type: requireClosed
          ? SketchAssistantPrimitive.circle
          : SketchAssistantPrimitive.arc,
      sourceReferenceCurveId: reference.id,
      center: center,
      radius: radius,
      startAngle: start,
      endAngle: end,
      points: unique,
      confidence: (1 - radialError / tolerance).clamp(0.0, 1.0),
    );
  }

  (SketchVector, double)? _fitCircle(List<SketchVector> points) {
    var sx = 0.0, sy = 0.0, sxx = 0.0, syy = 0.0, sxy = 0.0;
    var sb = 0.0, sxb = 0.0, syb = 0.0;
    for (final p in points) {
      sx += p.x;
      sy += p.y;
      sxx += p.x * p.x;
      syy += p.y * p.y;
      sxy += p.x * p.y;
      final b = -(p.x * p.x + p.y * p.y);
      sb += b;
      sxb += p.x * b;
      syb += p.y * b;
    }
    final solution = _solve3([
      [sxx, sxy, sx, sxb],
      [sxy, syy, sy, syb],
      [sx, sy, points.length.toDouble(), sb],
    ]);
    if (solution == null) return null;
    final center = SketchVector(-solution[0] / 2, -solution[1] / 2);
    final radius2 = center.dot(center) - solution[2];
    return radius2 > 0 && radius2.isFinite
        ? (center, math.sqrt(radius2))
        : null;
  }

  List<double>? _solve3(List<List<double>> matrix) {
    for (var column = 0; column < 3; column++) {
      var pivot = column;
      for (var row = column + 1; row < 3; row++) {
        if (matrix[row][column].abs() > matrix[pivot][column].abs()) {
          pivot = row;
        }
      }
      if (matrix[pivot][column].abs() <= 1e-12) return null;
      final swap = matrix[column];
      matrix[column] = matrix[pivot];
      matrix[pivot] = swap;
      final divisor = matrix[column][column];
      for (var item = column; item < 4; item++) {
        matrix[column][item] /= divisor;
      }
      for (var row = 0; row < 3; row++) {
        if (row == column) continue;
        final factor = matrix[row][column];
        for (var item = column; item < 4; item++) {
          matrix[row][item] -= factor * matrix[column][item];
        }
      }
    }
    return [matrix[0][3], matrix[1][3], matrix[2][3]];
  }

  double _segmentDistance(SketchVector p, SketchVector a, SketchVector b) {
    final ab = b - a, ap = p - a;
    final length2 = ab.dot(ab);
    final t = length2 <= 1e-20 ? 0.0 : (ap.dot(ab) / length2).clamp(0.0, 1.0);
    return _length(p - (a + ab.scale(t)));
  }

  double _length(SketchVector value) => math.sqrt(value.dot(value));
}
