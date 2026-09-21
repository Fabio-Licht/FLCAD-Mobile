import 'package:flcad_mobile/app/desktop/alignment_coordinate_system_selection.dart';
import 'package:flcad_mobile/core/cad_document/alignment_coordinate_system.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AlignmentCoordinateSystemSelectionController controller;

  setUp(() => controller = AlignmentCoordinateSystemSelectionController());
  tearDown(() => controller.dispose());

  test('captures plane axis and point sequentially without multiselection', () {
    controller.begin(AlignmentCoordinateSystemSlot.plane);
    expect(
      controller.capture(
        'project:world:xy-plane',
        planeCandidateIds: {'project:world:xy-plane'},
        axisCandidateIds: {'project:world:y-axis'},
        pointCandidateIds: {'project:world:origin'},
      ),
      AlignmentCoordinateSystemCaptureResult.accepted,
    );
    controller.begin(AlignmentCoordinateSystemSlot.axis);
    expect(
      controller.capture(
        'project:world:y-axis',
        planeCandidateIds: {'project:world:xy-plane'},
        axisCandidateIds: {'project:world:y-axis'},
        pointCandidateIds: {'project:world:origin'},
      ),
      AlignmentCoordinateSystemCaptureResult.accepted,
    );
    controller.begin(AlignmentCoordinateSystemSlot.point);
    expect(
      controller.capture(
        'project:world:origin',
        planeCandidateIds: {'project:world:xy-plane'},
        axisCandidateIds: {'project:world:y-axis'},
        pointCandidateIds: {'project:world:origin'},
      ),
      AlignmentCoordinateSystemCaptureResult.accepted,
    );
    expect(controller.complete, isTrue);
  });

  test(
    'incompatible click retains the active slot and clear resets preview state',
    () {
      controller.begin(AlignmentCoordinateSystemSlot.point);
      expect(
        controller.capture(
          'not-a-point',
          planeCandidateIds: {'plane'},
          axisCandidateIds: {'axis'},
          pointCandidateIds: {'point'},
        ),
        AlignmentCoordinateSystemCaptureResult.incompatible,
      );
      expect(controller.activeSlot, AlignmentCoordinateSystemSlot.point);
      controller.clear();
      expect(controller.active, isFalse);
      expect(controller.complete, isFalse);
    },
  );

  test(
    'lists remain an alternative and notify when all fields are complete',
    () {
      var previewRequests = 0;
      controller.addListener(() {
        if (controller.complete) previewRequests++;
      });
      controller.choose(AlignmentCoordinateSystemSlot.plane, 'plane');
      controller.choose(AlignmentCoordinateSystemSlot.axis, 'axis');
      controller.choose(AlignmentCoordinateSystemSlot.point, 'point');
      expect(controller.complete, isTrue);
      expect(previewRequests, 1);
    },
  );

  test('manual and viewport origins do not create an auxiliary point', () {
    controller.choose(AlignmentCoordinateSystemSlot.plane, 'plane');
    controller.choose(AlignmentCoordinateSystemSlot.axis, 'axis');
    controller.chooseOriginKind(AlignmentCoordinateSystemOriginKind.manual);
    controller.setManualOrigin(
      const Vector3(25, -40, 12.5),
      kind: AlignmentCoordinateSystemOriginKind.manual,
    );
    expect(controller.complete, isTrue);
    expect(controller.pointEntityId, isNull);

    controller.chooseOriginKind(AlignmentCoordinateSystemOriginKind.viewport);
    expect(controller.complete, isFalse);
    controller.begin(AlignmentCoordinateSystemSlot.viewportOrigin);
    expect(controller.active, isTrue);
    controller.setManualOrigin(
      const Vector3(3.25, 4.5, -7.75),
      kind: AlignmentCoordinateSystemOriginKind.viewport,
    );
    expect(controller.complete, isTrue);
    expect(controller.active, isFalse);
    expect(controller.manualOrigin, const Vector3(3.25, 4.5, -7.75));
  });

  test('switching origin modes clears capture and stale values', () {
    controller.chooseOriginKind(AlignmentCoordinateSystemOriginKind.viewport);
    controller.begin(AlignmentCoordinateSystemSlot.viewportOrigin);
    controller.chooseOriginKind(AlignmentCoordinateSystemOriginKind.manual);
    expect(controller.active, isFalse);
    expect(controller.manualOrigin, isNull);
    expect(controller.pointEntityId, isNull);

    controller.setManualOrigin(
      const Vector3(1, 2, 3),
      kind: AlignmentCoordinateSystemOriginKind.manual,
    );
    controller.chooseOriginKind(
      AlignmentCoordinateSystemOriginKind.referencePoint,
    );
    expect(controller.manualOrigin, isNull);
    expect(controller.complete, isFalse);
  });

  test(
    'manual coordinate parser accepts decimal comma and rejects non-finite',
    () {
      expect(parseAlignmentCoordinateMm('12,5'), 12.5);
      expect(parseAlignmentCoordinateMm(' -40.125 '), -40.125);
      expect(parseAlignmentCoordinateMm('NaN'), isNull);
      expect(parseAlignmentCoordinateMm('Infinity'), isNull);
      expect(parseAlignmentCoordinateMm(''), isNull);
    },
  );
}
