import 'package:flcad_mobile/core/sketch_editor/snapping/sketch_coordinate_magnet.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zero axes and round coordinates are acquired exactly', () {
    final magnet = SketchCoordinateMagnet();
    final result = magnet.apply(
      pointer: const SketchVector(.7, 10.6),
      candidate: const SketchVector(.68, 10.58),
      worldPerPixel: .1,
    );
    expect(result.x, 0);
    expect(result.y, 10);
    expect(magnet.lockedX, 0);
    expect(magnet.lockedY, 10);
  });

  test('capture is sticky then releases outside the wider band', () {
    final magnet = SketchCoordinateMagnet();
    magnet.apply(
      pointer: const SketchVector(.8, 3),
      candidate: const SketchVector(.8, 3),
      worldPerPixel: .1,
    );
    final held = magnet.apply(
      pointer: const SketchVector(1.3, 3),
      candidate: const SketchVector(1.3, 3),
      worldPerPixel: .1,
    );
    expect(held.x, 0);
    final released = magnet.apply(
      pointer: const SketchVector(2, 3),
      candidate: const SketchVector(2, 3),
      worldPerPixel: .1,
    );
    expect(released.x, 2);
    expect(magnet.lockedX, isNull);
  });

  test('magnet respects zoom and can be cleared without model state', () {
    final magnet = SketchCoordinateMagnet();
    final fine = magnet.apply(
      pointer: const SketchVector(.055, -.052),
      candidate: const SketchVector(.055, -.052),
      worldPerPixel: .01,
    );
    expect(fine.x, 0);
    expect(fine.y, 0);
    magnet.clear();
    expect(magnet.lockedX, isNull);
    expect(magnet.lockedY, isNull);
    final free = magnet.apply(
      pointer: const SketchVector(2.27, 2.27),
      candidate: const SketchVector(2.27, 2.27),
      worldPerPixel: .01,
    );
    expect(free.x, 2.27);
    expect(free.y, 2.27);
  });
}
