import 'package:flutter_test/flutter_test.dart';
import 'package:flcad_mobile/app/engineering_bridge/operational_reverse_engineering_controller.dart';
import 'package:flcad_mobile/core/sketch_editor/models/editor_models.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';

void main() {
  group('G-122 Professional Circle geometry', () {
    test('center plus radius preserves center and radial distance', () {
      final circle =
          OperationalReverseEngineeringController.professionalCircleDefinition(
            SketchCircleMode.centerRadius,
            const [SketchVector(2, 3), SketchVector(5, 7)],
          )!;
      expect(circle.center, const SketchVector(2, 3));
      expect(circle.radius, closeTo(5, 1e-12));
    });

    test('center plus diameter converts diameter to radius', () {
      final circle =
          OperationalReverseEngineeringController.professionalCircleDefinition(
            SketchCircleMode.centerDiameter,
            const [SketchVector(1, 1), SketchVector(11, 1)],
          )!;
      expect(circle.center, const SketchVector(1, 1));
      expect(circle.radius, closeTo(5, 1e-12));
    });

    test('two points define the diameter', () {
      final circle =
          OperationalReverseEngineeringController.professionalCircleDefinition(
            SketchCircleMode.twoPoints,
            const [SketchVector(-4, 2), SketchVector(6, 2)],
          )!;
      expect(circle.center.x, closeTo(1, 1e-12));
      expect(circle.center.y, closeTo(2, 1e-12));
      expect(circle.radius, closeTo(5, 1e-12));
    });

    test('three points produce their unique circumcircle', () {
      final circle =
          OperationalReverseEngineeringController.professionalCircleDefinition(
            SketchCircleMode.threePoints,
            const [SketchVector(5, 0), SketchVector(0, 5), SketchVector(-5, 0)],
          )!;
      expect(circle.center.x, closeTo(0, 1e-12));
      expect(circle.center.y, closeTo(0, 1e-12));
      expect(circle.radius, closeTo(5, 1e-12));
    });

    test('collinear three-point input is rejected', () {
      expect(
        OperationalReverseEngineeringController.professionalCircleDefinition(
          SketchCircleMode.threePoints,
          const [SketchVector(0, 0), SketchVector(1, 1), SketchVector(2, 2)],
        ),
        isNull,
      );
    });

    test('tangency modes remain preparation-only', () {
      for (final mode in const [
        SketchCircleMode.tangentRadius,
        SketchCircleMode.tangentTangentRadius,
        SketchCircleMode.threeTangencies,
      ]) {
        expect(mode.implemented, isFalse);
        expect(
          OperationalReverseEngineeringController.professionalCircleDefinition(
            mode,
            const [SketchVector(0, 0), SketchVector(1, 0)],
          ),
          isNull,
        );
      }
    });
  });
}
