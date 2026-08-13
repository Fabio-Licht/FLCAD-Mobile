import '../models/geometry.dart';
import '../models/smart_region.dart';

abstract interface class RegionRenderer {
  Future<void> render(MeshTopology mesh, List<SmartRegion> regions);
}

class RegionRenderDescriptor {
  const RegionRenderDescriptor(
    this.regionId,
    this.color,
    this.visible,
    this.weights,
  );
  final String regionId, color;
  final bool visible;
  final Map<int, double> weights;
}
