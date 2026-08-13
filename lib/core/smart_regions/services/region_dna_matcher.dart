import 'dart:math' as math;
import '../models/region_dna.dart';

class RegionDNAMatcher {
  const RegionDNAMatcher();
  double similarity(RegionDNA a, RegionDNA b) {
    final normal = _cosine(a.normalHistogram, b.normalHistogram),
        curve = _cosine(a.curvatureHistogram, b.curvatureHistogram),
        area =
            1 -
            (a.area - b.area).abs() / math.max(math.max(a.area, b.area), 1e-9),
        centroidDistance = math.sqrt(
          List.generate(
            3,
            (i) =>
                (a.centroid[i] - b.centroid[i]) *
                (a.centroid[i] - b.centroid[i]),
          ).fold<double>(0, (x, y) => x + y),
        );
    final centroid = 1 / (1 + centroidDistance),
        topology = a.topologySignature == b.topologySignature ? 1.0 : .5;
    return (normal * .25 +
            curve * .2 +
            area.clamp(0, 1) * .2 +
            centroid * .15 +
            topology * .2)
        .clamp(0, 1);
  }

  double _cosine(List<double> a, List<double> b) {
    var dot = 0.0, aa = 0.0, bb = 0.0;
    for (var i = 0; i < math.min(a.length, b.length); i++) {
      dot += a[i] * b[i];
      aa += a[i] * a[i];
      bb += b[i] * b[i];
    }
    return aa == 0 || bb == 0 ? 0 : dot / math.sqrt(aa * bb);
  }
}
