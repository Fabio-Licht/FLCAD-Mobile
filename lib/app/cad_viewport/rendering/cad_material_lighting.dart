import 'dart:math' as math;
import 'dart:ui';

import '../../../core/geometric_kernel/geometry/vectors.dart';

/// Camera-linked, bounded response. Normals retain their surface orientation;
/// neither back faces nor transparency cause an implicit normal inversion.
abstract final class CadMaterialLighting {
  static double signal(Vector3 normal, Vector3 key, Vector3 fill) =>
      .42 +
      .46 * math.max(0, normal.dot(key)).clamp(0, 1) +
      .12 * math.max(0, normal.dot(fill)).clamp(0, 1);

  static Color highlight(
    Color base, {
    required bool selected,
    required bool hovered,
    required bool transparent,
  }) => selected
      ? Color.lerp(base, const Color(0xffffb02e), transparent ? .18 : .28)!
      : hovered
      ? Color.lerp(base, const Color(0xff38d6ff), transparent ? .12 : .24)!
      : base;
}
