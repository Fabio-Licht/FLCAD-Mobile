import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../models/live_reconstruction_models.dart';

class ReconstructionGraphBuilder {
  const ReconstructionGraphBuilder();
  ReconstructionDependencyGraph build(
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final nodes = <String, String>{}, edges = <String, Set<String>>{};
    void node(String id, String type) {
      nodes[id] = type;
      edges.putIfAbsent(id, () => <String>{});
    }

    void connect(String from, String to) {
      node(from, nodes[from] ?? 'object');
      node(to, nodes[to] ?? 'object');
      edges[from]!.add(to);
    }

    for (final patch in topology.patches) {
      node(patch.id, 'patch');
      node(patch.recognitionRegionId, 'region');
      connect(patch.recognitionRegionId, patch.id);
      for (final boundary in patch.boundaryIds) {
        node(boundary, 'boundary');
        connect(patch.id, boundary);
      }
      for (final neighbor in patch.adjacentPatchIds) {
        connect(patch.id, neighbor);
      }
    }
    for (final item in quality.continuity) {
      node(item.id, 'continuity');
      connect(item.firstPatchId, item.id);
      if (item.secondPatchId != item.firstPatchId) {
        connect(item.secondPatchId, item.id);
      }
    }
    for (final patch in quality.patchQualities) {
      for (final kind in const [
        'reflection',
        'zebra',
        'draft',
        'validation',
        'analytics',
        'heatMap',
      ]) {
        final id = '$kind:${patch.patch.id}';
        node(id, kind);
        connect(patch.patch.id, id);
      }
    }
    return ReconstructionDependencyGraph(Map.unmodifiable(nodes), {
      for (final e in edges.entries) e.key: Set.unmodifiable(e.value),
    });
  }
}
