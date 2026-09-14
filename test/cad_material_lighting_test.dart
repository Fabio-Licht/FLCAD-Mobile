import 'dart:math' as math;
import 'dart:ui';

import 'package:flcad_mobile/app/cad_viewport/rendering/cad_material_lighting.dart';
import 'package:flcad_mobile/app/cad_viewport/rendering/cad_tonal_separation.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final key = const Vector3(-.22, .48, .78).normalized;
  final fill = const Vector3(.66, -.28, .42).normalized;
  test('camera-linked light is invariant under a common rigid rotation', () {
    final normal = const Vector3(.2, -.6, .7).normalized;
    final expected = CadMaterialLighting.signal(normal, key, fill);
    Vector3 rotate(Vector3 v, double a, double b) {
      final x = v.x * math.cos(a) - v.y * math.sin(a);
      final y = v.x * math.sin(a) + v.y * math.cos(a);
      return Vector3(
        x,
        y * math.cos(b) - v.z * math.sin(b),
        y * math.sin(b) + v.z * math.cos(b),
      );
    }

    for (var step = 0; step < 360; step += 5) {
      final a = step * math.pi / 180;
      final b = a * .73;
      expect(
        CadMaterialLighting.signal(
          rotate(normal, a, b),
          rotate(key, a, b),
          rotate(fill, a, b),
        ),
        closeTo(expected, 1e-12),
      );
    }
  });
  test('every oriented normal retains bounded ambient without inversion', () {
    for (var latitude = -90; latitude <= 90; latitude += 5) {
      for (var longitude = 0; longitude < 360; longitude += 5) {
        final a = latitude * math.pi / 180, b = longitude * math.pi / 180;
        final n = Vector3(
          math.cos(a) * math.cos(b),
          math.cos(a) * math.sin(b),
          math.sin(a),
        );
        final value = CadMaterialLighting.signal(n, key, fill);
        expect(value, inInclusiveRange(.42, 1));
        final color = CadTonalSeparation.shade(const Color(0xff7899ad), value);
        expect(color.computeLuminance(), greaterThan(.05));
      }
    }
    expect(CadMaterialLighting.signal(const Vector3(0, 0, -1), key, fill), .42);
    expect(
      CadMaterialLighting.signal(const Vector3(0, 0, 1), key, fill),
      greaterThan(.8),
    );
  });
  test('transparent selection preserves material and alpha in composition', () {
    const base = Color(0xff7899ad);
    for (final hovered in [false, true]) {
      for (final selected in [false, true]) {
        final tint = CadMaterialLighting.highlight(
          base,
          selected: selected,
          hovered: hovered,
          transparent: true,
        );
        final color = CadTonalSeparation.shade(tint, .65, alpha: .24);
        expect(color.a, closeTo(.24, 1e-6));
        expect((tint.r - base.r).abs(), lessThan(.19));
        expect((tint.g - base.g).abs(), lessThan(.19));
        expect((tint.b - base.b).abs(), lessThan(.19));
      }
    }
    expect(
      CadMaterialLighting.highlight(
        base,
        selected: false,
        hovered: false,
        transparent: false,
      ),
      base,
    );
    final plain = CadTonalSeparation.shade(base, .65, alpha: .24);
    final selected = CadTonalSeparation.shade(
      CadMaterialLighting.highlight(
        base,
        selected: true,
        hovered: false,
        transparent: true,
      ),
      .65,
      alpha: .24,
    );
    final background = const Color(0xff13181d);
    final a = Color.alphaBlend(plain, background);
    final b = Color.alphaBlend(selected, background);
    expect((a.computeLuminance() - b.computeLuminance()).abs(), lessThan(.025));
  });
}
