import 'package:flcad_mobile/app/desktop/inspector_value_formatter.dart';
import 'package:flcad_mobile/app/desktop/plane_axis_intersection_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sequential plane-axis viewport capture', () {
    late PlaneAxisIntersectionSelectionController controller;

    setUp(() => controller = PlaneAxisIntersectionSelectionController());
    tearDown(() => controller.dispose());

    test(
      'captures WCS plane then reference axis without global multiselect',
      () {
        controller.begin(PlaneAxisIntersectionSlot.plane);
        expect(
          controller.capture(
            'project:world:xy-plane',
            planeCandidateIds: {'project:world:xy-plane'},
            axisCandidateIds: {'managed-axis'},
          ),
          PlaneAxisIntersectionCaptureResult.accepted,
        );
        expect(controller.planeEntityId, 'project:world:xy-plane');
        expect(controller.active, isFalse);

        controller.begin(PlaneAxisIntersectionSlot.axis);
        expect(
          controller.capture(
            'managed-axis',
            planeCandidateIds: {'project:world:xy-plane'},
            axisCandidateIds: {'managed-axis'},
          ),
          PlaneAxisIntersectionCaptureResult.accepted,
        );
        expect(controller.axisEntityId, 'managed-axis');
        expect(controller.complete, isTrue);
      },
    );

    test('incompatible click reports rejection and keeps the slot active', () {
      controller.begin(PlaneAxisIntersectionSlot.axis);
      expect(
        controller.capture(
          'not-an-axis',
          planeCandidateIds: {'plane'},
          axisCandidateIds: {'axis'},
        ),
        PlaneAxisIntersectionCaptureResult.incompatible,
      );
      expect(controller.activeSlot, PlaneAxisIntersectionSlot.axis);
      expect(controller.axisEntityId, isNull);
    });

    test('list choice remains an alternative and clear removes all state', () {
      var previewRequests = 0;
      controller.addListener(() {
        if (controller.complete) previewRequests++;
      });
      controller.choose(PlaneAxisIntersectionSlot.plane, 'listed-plane');
      controller.choose(PlaneAxisIntersectionSlot.axis, 'listed-axis');
      expect(controller.complete, isTrue);
      expect(previewRequests, 1);

      controller.clear();
      expect(controller.activeSlot, isNull);
      expect(controller.planeEntityId, isNull);
      expect(controller.axisEntityId, isNull);
    });
  });

  group('Inspector metric coordinates', () {
    test('formats negative, numeric zero and ordinary values', () {
      expect(
        InspectorValueFormatter.coordinateMm([-40, -0.00001, -25.9]),
        '[-40.000, 0.000, -25.900] mm',
      );
      expect(
        InspectorValueFormatter.coordinateMm([1.23456, 0, 98.7654]),
        '[1.235, 0.000, 98.765] mm',
      );
    });

    test('formats large finite values without scientific notation', () {
      expect(
        InspectorValueFormatter.coordinateMm([123456789, -1000000, 0.5]),
        '[123456789.000, -1000000.000, 0.500] mm',
      );
    });

    test('formatting does not mutate raw coordinates', () {
      final raw = <double>[-40.0000000004, 1e-12, -25.8999999997];
      final exact = List<double>.of(raw);
      InspectorValueFormatter.coordinateMm(raw);
      expect(raw, exact);
    });
  });
}
