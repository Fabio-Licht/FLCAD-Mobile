import 'dart:math' as math;

import 'package:flcad_mobile/core/sketch_assistant/sketch_assistant.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = SketchAssistantEngine();

  test('suggests a straight reference segment without creating geometry', () {
    final reference = SketchAssistantReference('ReferenceCurve001', [
      for (var i = 0; i < 10; i++)
        (SketchVector(i.toDouble(), 0), SketchVector(i + 1.0, 0)),
    ]);
    final suggestion = engine.suggest(
      requested: SketchAssistantPrimitive.line,
      cursor: const SketchVector(5, .02),
      anchor: const SketchVector(0, 0),
      references: [reference],
      precision: SketchAssistantPrecision.high,
    );
    expect(suggestion?.type, SketchAssistantPrimitive.line);
    expect(suggestion?.sourceReferenceCurveId, 'ReferenceCurve001');
    expect(suggestion?.label, 'Linha sugerida');
  });

  test('recognizes circle and reports its measured diameter', () {
    final reference = SketchAssistantReference(
      'ReferenceCurve002',
      _roundSegments(radius: 30, end: 2 * math.pi, count: 72),
    );
    final suggestion = engine.suggest(
      requested: SketchAssistantPrimitive.circle,
      cursor: const SketchVector(30, 0),
      references: [reference],
      precision: SketchAssistantPrecision.high,
    );
    expect(suggestion?.type, SketchAssistantPrimitive.circle);
    expect(suggestion?.radius, closeTo(30, .01));
    expect(suggestion?.label, contains('60.00'));
  });

  test('recognizes an open constant-radius run as an arc', () {
    final reference = SketchAssistantReference(
      'ReferenceCurve003',
      _roundSegments(radius: 25.02, end: math.pi, count: 40),
    );
    final suggestion = engine.suggest(
      requested: SketchAssistantPrimitive.arc,
      cursor: const SketchVector(25.02, 0),
      references: [reference],
      precision: SketchAssistantPrecision.high,
    );
    expect(suggestion?.type, SketchAssistantPrimitive.arc);
    expect(suggestion?.radius, closeTo(25.02, .02));
    expect(suggestion?.label, contains('25.02'));
  });

  test('precision setting controls acceptance tolerance', () {
    final noisy = SketchAssistantReference('ReferenceCurve004', [
      for (var i = 0; i < 8; i++)
        (
          SketchVector(i.toDouble(), i.isEven ? .15 : -.15),
          SketchVector(i + 1.0, i.isEven ? .15 : -.15),
        ),
    ]);
    SketchAssistantSuggestion? run(SketchAssistantPrecision precision) =>
        engine.suggest(
          requested: SketchAssistantPrimitive.line,
          cursor: const SketchVector(4, .15),
          references: [noisy],
          precision: precision,
        );
    expect(run(SketchAssistantPrecision.high), isNull);
    expect(run(SketchAssistantPrecision.low), isNotNull);
  });
}

List<(SketchVector, SketchVector)> _roundSegments({
  required double radius,
  required double end,
  required int count,
}) => [
  for (var i = 0; i < count; i++)
    (
      SketchVector(
        radius * math.cos(end * i / count),
        radius * math.sin(end * i / count),
      ),
      SketchVector(
        radius * math.cos(end * (i + 1) / count),
        radius * math.sin(end * (i + 1) / count),
      ),
    ),
];
