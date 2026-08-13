import '../models/kernel_models.dart';

class GeometryGraphNode {
  const GeometryGraphNode(this.handle, this.metadata);
  final ShapeHandle handle;
  final Map<String, dynamic> metadata;
}

class GeometryGraphEdge {
  const GeometryGraphEdge(this.sourceId, this.targetId, this.relation);
  final String sourceId, targetId, relation;
}

class GeometryGraph {
  final Map<String, GeometryGraphNode> nodes = {};
  final List<GeometryGraphEdge> edges = [];
  void add(GeometryGraphNode node) => nodes[node.handle.persistentId] = node;
  void connect(GeometryGraphEdge edge) {
    if (!nodes.containsKey(edge.sourceId) ||
        !nodes.containsKey(edge.targetId)) {
      throw StateError('Geometry graph node missing');
    }
    final source = nodes[edge.sourceId]!.handle.type.index,
        target = nodes[edge.targetId]!.handle.type.index;
    if (source >= target) {
      throw StateError('Topology hierarchy must flow Vertex to Solid/Compound');
    }
    if (_impact(edge.targetId).contains(edge.sourceId)) {
      throw StateError('Geometry graph cycle');
    }
    edges.add(edge);
  }

  Set<String> _impact(String id) {
    final result = <String>{}, queue = [id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final e in edges.where((e) => e.sourceId == current)) {
        if (result.add(e.targetId)) queue.add(e.targetId);
      }
    }
    return result;
  }
}
