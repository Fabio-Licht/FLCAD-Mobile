import '../../surface_intelligence/graph/surface_dependency_graph.dart';
import '../models/surface_generation_models.dart';

class GeneratedSurfaceGraphNode {
  const GeneratedSurfaceGraphNode(this.surface);
  final GeneratedSurface surface;
}

class GeneratedSurfaceGraph {
  final Map<String, GeneratedSurfaceGraphNode> nodes = {};
  final List<SurfaceGraphEdge> edges = [];
  void add(GeneratedSurface surface) =>
      nodes[surface.surfaceId] = GeneratedSurfaceGraphNode(surface);
  void connect(SurfaceGraphEdge edge) {
    if (!nodes.containsKey(edge.sourceId) ||
        !nodes.containsKey(edge.targetId)) {
      throw StateError('Generated surface graph node missing');
    }
    edges.add(edge);
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes.values.map((e) => e.surface.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };
}
