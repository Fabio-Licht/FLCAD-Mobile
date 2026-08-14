import 'dart:math' as math;
import '../models/surface_morph_models.dart';

class AnchorEngine {
  const AnchorEngine();
  void validate(List<MorphAnchor> anchors) {
    final ids = <String>{};
    for (final anchor in anchors) {
      if (!ids.add(anchor.id)) {
        throw StateError('Duplicate morph anchor: ${anchor.id}');
      }
      if (anchor.position.length != 3 ||
          anchor.position.any((e) => !e.isFinite)) {
        throw StateError('Invalid morph anchor position: ${anchor.id}');
      }
      if (anchor.strength < 0 || anchor.strength > 1) {
        throw StateError('Invalid morph anchor strength: ${anchor.id}');
      }
    }
  }
}

class InfluenceEngine {
  const InfluenceEngine();
  InfluenceRegion calculate(
    List<MorphAnchor> anchors,
    double radius,
    FalloffType falloff, {
    List<double> customCurve = const [],
  }) {
    if (radius <= 0 || !radius.isFinite) {
      throw StateError('Influence radius must be positive');
    }
    double weight(int index) {
      final t = anchors.length <= 1 ? 0.0 : index / (anchors.length - 1);
      return switch (falloff) {
        FalloffType.linear => 1 - t,
        FalloffType.smooth => 1 - (t * t * (3 - 2 * t)),
        FalloffType.gaussian => math.exp(-4 * t * t),
        FalloffType.bell => .5 * (1 + math.cos(math.pi * t)),
        FalloffType.customCurve =>
          customCurve.isEmpty
              ? (throw StateError('Custom falloff curve is empty'))
              : customCurve[math.min(index, customCurve.length - 1)]
                    .clamp(0.0, 1.0)
                    .toDouble(),
      };
    }

    return InfluenceRegion(
      radius: radius,
      falloff: falloff,
      weights: {
        for (var i = 0; i < anchors.length; i++)
          anchors[i].id: weight(i) * anchors[i].strength,
      },
      customCurve: List.unmodifiable(customCurve),
    );
  }
}
