import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flcad_mobile/core/sketch_editor/health/sketch_health_analyzer.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';

void main() {
  const analyzer = SketchHealthAnalyzer();

  test('accepts a closed mixed line and arc profile', () {
    final report = analyzer.analyze([
      SketchLine(
        const SketchVector(0, 0),
        const SketchVector(10, 0),
        id: 'bottom',
      ),
      SketchLine(
        const SketchVector(10, 0),
        const SketchVector(10, 5),
        id: 'right',
      ),
      SketchArc(const SketchVector(5, 5), 5, 0, math.pi, id: 'arc'),
      SketchLine(
        const SketchVector(0, 5),
        const SketchVector(0, 0),
        id: 'left',
      ),
    ]);

    expect(report.closedProfile, isTrue);
    expect(report.issues, isEmpty);
    expect(report.readyForSurface, isTrue);
  });

  test('reports a measurable, safely repairable gap', () {
    final report = analyzer.analyze([
      SketchLine(const SketchVector(0, 0), const SketchVector(10, 0), id: 'a'),
      SketchLine(
        const SketchVector(10.018, 0),
        const SketchVector(10, 10),
        id: 'b',
      ),
    ]);
    final gap = report.ofType(SketchHealthIssueType.gap).single;

    expect(gap.distance, closeTo(.018, 1e-9));
    expect(gap.entityIds, containsAll(['a', 'b']));
    expect(gap.endpointReferences, hasLength(2));
    expect(gap.canAutoHeal, isTrue);
    expect(report.readyForSurface, isFalse);
  });

  test('detects reversed duplicates, overlap and coincident circles', () {
    final report = analyzer.analyze([
      SketchLine(const SketchVector(0, 0), const SketchVector(10, 0), id: 'a'),
      SketchLine(const SketchVector(10, 0), const SketchVector(0, 0), id: 'b'),
      SketchLine(const SketchVector(3, 0), const SketchVector(12, 0), id: 'c'),
      SketchCircle(const SketchVector(20, 20), 4, id: 'c1'),
      SketchCircle(const SketchVector(20, 20), 4, id: 'c2'),
    ]);

    expect(report.ofType(SketchHealthIssueType.duplicate), hasLength(2));
    expect(report.ofType(SketchHealthIssueType.overlap), isNotEmpty);
  });

  test('detects an interior crossing and tiny geometry', () {
    final report = analyzer.analyze([
      SketchLine(const SketchVector(0, 0), const SketchVector(10, 10), id: 'a'),
      SketchLine(const SketchVector(0, 10), const SketchVector(10, 0), id: 'b'),
      SketchLine(
        const SketchVector(20, 20),
        const SketchVector(20.001, 20),
        id: 'tiny',
      ),
    ]);

    expect(report.hasSelfIntersections, isTrue);
    expect(report.hasTinyGeometry, isTrue);
    expect(report.hasOpenEnds, isTrue);
  });

  test('analysis never mutates authoritative geometry', () {
    final line = SketchLine(
      const SketchVector(0, 0),
      const SketchVector(1, 0),
      id: 'line',
    );
    final before = line.toJson().toString();
    analyzer.analyze([line]);
    expect(line.toJson().toString(), before);
  });
}
