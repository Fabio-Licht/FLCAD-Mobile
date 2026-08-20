import 'dart:math' as math;

import 'package:flcad_mobile/core/sketch_editor/inferencing/sketch_inference_engine.dart';
import 'package:flcad_mobile/core/sketch_editor/snapping/editor_snapping.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = SketchInferenceEngine();

  test('H and V change preview position without creating constraints', () {
    final horizontal = engine.inferLine(
      cursor: const SketchVector(10, .2),
      start: const SketchVector(0, 0),
      entities: const [],
    );
    final vertical = engine.inferLine(
      cursor: const SketchVector(.2, 10),
      start: const SketchVector(0, 0),
      entities: const [],
    );

    expect(horizontal?.type, SketchInferenceType.horizontal);
    expect(horizontal?.position.y, closeTo(0, 1e-9));
    expect(vertical?.type, SketchInferenceType.vertical);
    expect(vertical?.position.x, closeTo(0, 1e-9));
  });

  test('H and V preserve the direction chosen by the pointer', () {
    final left = engine.inferLine(
      cursor: const SketchVector(-10, .2),
      start: const SketchVector(0, 0),
      entities: const [],
    );
    final down = engine.inferLine(
      cursor: const SketchVector(.2, -10),
      start: const SketchVector(0, 0),
      entities: const [],
    );

    expect(left?.type, SketchInferenceType.horizontal);
    expect(left!.position.x, lessThan(0));
    expect(left.position.y, closeTo(0, 1e-9));
    expect(down?.type, SketchInferenceType.vertical);
    expect(down!.position.x, closeTo(0, 1e-9));
    expect(down.position.y, lessThan(0));
  });

  test('only highest priority spatial inference is returned', () {
    const cursor = SketchVector(3, 4);
    final inference = engine.inferLine(
      cursor: cursor,
      start: const SketchVector(0, 0),
      entities: const [],
      snap: const SnapCandidate(
        EditorSnapType.endpoint,
        cursor,
        0,
        entityId: 'line:reference',
      ),
    );

    expect(inference?.type, SketchInferenceType.endpoint);
    expect(inference?.type.glyph, '●');
  });

  test('parallel and perpendicular preserve proposed line length', () {
    final reference = SketchLine(
      const SketchVector(0, 0),
      const SketchVector(5, 2),
      id: 'reference',
    );
    final angle = math.atan2(2, 5);
    final parallel = engine.inferLine(
      cursor: SketchVector(
        10 * math.cos(angle + .01),
        10 * math.sin(angle + .01),
      ),
      start: const SketchVector(0, 0),
      entities: [reference],
    );
    final perpendicular = engine.inferLine(
      cursor: SketchVector(
        8 * math.cos(angle + math.pi / 2 + .01),
        8 * math.sin(angle + math.pi / 2 + .01),
      ),
      start: const SketchVector(0, 0),
      entities: [reference],
    );

    expect(parallel?.type, SketchInferenceType.parallel);
    expect(perpendicular?.type, SketchInferenceType.perpendicular);
  });

  test('tangent suggests the closest real tangency point', () {
    final circle = SketchCircle(const SketchVector(0, 0), 1, id: 'circle');
    final inference = engine.inferLine(
      cursor: const SketchVector(-.2, .98),
      start: const SketchVector(-5, 0),
      entities: [circle],
      spatialTolerance: .5,
    );

    expect(inference?.type, SketchInferenceType.tangent);
    expect(inference?.referenceEntityId, 'circle');
  });
}
