import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flcad_mobile/app/cad_viewport/rendering/sketch_scene_adapter.dart';
import 'package:flcad_mobile/app/engineering_bridge/operational_reverse_engineering_controller.dart';
import 'package:flcad_mobile/core/sketch_editor/models/editor_models.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';

void main() {
  group('G-123 Professional Arc', () {
    test('center mode derives radius and endpoint angles', () {
      final arc =
          OperationalReverseEngineeringController.professionalArcDefinition(
            SketchArcMode.center,
            const [SketchVector(2, 3), SketchVector(7, 3), SketchVector(2, 8)],
          )!;
      expect(arc.center.x, 2);
      expect(arc.center.y, 3);
      expect(arc.radius, closeTo(5, 1e-12));
      expect(arc.startAngle, closeTo(0, 1e-12));
      expect(arc.endAngle, closeTo(math.pi / 2, 1e-12));
    });

    test(
      'three-point mode creates the circumcircle arc through middle point',
      () {
        final arc =
            OperationalReverseEngineeringController.professionalArcDefinition(
              SketchArcMode.threePoints,
              const [
                SketchVector(5, 0),
                SketchVector(0, 5),
                SketchVector(-5, 0),
              ],
            )!;
        expect(arc.center.x, closeTo(0, 1e-12));
        expect(arc.center.y, closeTo(0, 1e-12));
        expect(arc.radius, closeTo(5, 1e-12));
        expect(arc.endAngle - arc.startAngle, closeTo(math.pi, 1e-12));
      },
    );

    test('three-point mode preserves clockwise arc orientation', () {
      final arc =
          OperationalReverseEngineeringController.professionalArcDefinition(
            SketchArcMode.threePoints,
            const [
              SketchVector(5, 0),
              SketchVector(0, -5),
              SketchVector(-5, 0),
            ],
          )!;
      expect(arc.endAngle - arc.startAngle, closeTo(-math.pi, 1e-12));
    });

    test('collinear points and preparation-only tangent mode are rejected', () {
      expect(
        OperationalReverseEngineeringController.professionalArcDefinition(
          SketchArcMode.threePoints,
          const [SketchVector(0, 0), SketchVector(1, 1), SketchVector(2, 2)],
        ),
        isNull,
      );
      expect(SketchArcMode.tangent.implemented, isFalse);
      expect(
        OperationalReverseEngineeringController.professionalArcDefinition(
          SketchArcMode.tangent,
          const [SketchVector(0, 0), SketchVector(1, 0), SketchVector(0, 1)],
        ),
        isNull,
      );
    });

    test('line, circle and arc use exactly the same technical stroke', () {
      const adapter = SketchSceneAdapter();
      final entities = <SketchEntity>[
        SketchLine(const SketchVector(0, 0), const SketchVector(1, 0)),
        SketchCircle(const SketchVector(0, 0), 1),
        SketchArc(const SketchVector(0, 0), 1, 0, math.pi),
      ];
      final widths = entities
          .map((entity) => adapter.adapt(entity).geometry['strokeWidth'])
          .toSet();
      final colors = entities
          .map((entity) => adapter.adapt(entity).geometry['displayColor'])
          .toSet();
      expect(widths, {SketchSceneAdapter.technicalStrokeWidth});
      expect(colors, {'sketchGreen'});
    });
  });
}
