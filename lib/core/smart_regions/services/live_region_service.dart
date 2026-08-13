import '../filters/region_filter.dart';
import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

class LiveRegionService {
  final Map<String, RegionFilter> _filters = {};
  void bind(String regionId, RegionFilter filter) =>
      _filters[regionId] = filter;
  TriangleSelection refresh(String regionId, MeshTopology mesh) {
    final filter = _filters[regionId];
    if (filter == null) throw StateError('Live filter not registered');
    return filter.evaluate(mesh);
  }
}
