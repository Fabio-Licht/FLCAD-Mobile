import '../models/hybrid_surface_models.dart';

class HybridSurfaceNetwork {
  final Map<String, SurfaceNetworkNode> nodes = {};
  final List<SharedSurfaceBoundary> boundaries = [];
  void add(SurfaceNetworkNode node) => nodes[node.candidate.id] = node;
  void boundary(SharedSurfaceBoundary value) {
    if (value.surfaceIds.any((id) => !nodes.containsKey(id))) {
      throw StateError('Surface network node missing');
    }
    boundaries.add(value);
  }

  Set<String> neighbors(String id) => boundaries
      .where((e) => e.surfaceIds.contains(id))
      .expand((e) => e.surfaceIds)
      .where((e) => e != id)
      .toSet();
  Map<String, dynamic> toJson() => {
    'nodes': nodes.values.map((e) => e.toJson()).toList(),
    'boundaries': boundaries.map((e) => e.toJson()).toList(),
  };
}
