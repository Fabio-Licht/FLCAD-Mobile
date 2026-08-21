enum SurfaceDisplayMode { shaded, wireframe, shadedWithEdges, transparent }

class SurfaceTopology {
  const SurfaceTopology({
    required this.loops,
    required this.edges,
    required this.vertices,
    required this.area,
    required this.perimeter,
  });

  final List<SurfaceLoop> loops;
  final List<SurfaceEdge> edges;
  final List<SurfaceVertex> vertices;
  final double area;
  final double perimeter;

  Map<String, dynamic> toJson() => {
    'loops': loops.map((item) => item.toJson()).toList(),
    'edges': edges.map((item) => item.toJson()).toList(),
    'vertices': vertices.map((item) => item.toJson()).toList(),
    'area': area,
    'perimeter': perimeter,
  };

  factory SurfaceTopology.fromJson(Map<String, dynamic> json) =>
      SurfaceTopology(
        loops: (json['loops'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => SurfaceLoop.fromJson(item.cast<String, dynamic>()))
            .toList(),
        edges: (json['edges'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => SurfaceEdge.fromJson(item.cast<String, dynamic>()))
            .toList(),
        vertices: (json['vertices'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => SurfaceVertex.fromJson(item.cast<String, dynamic>()))
            .toList(),
        area: (json['area'] as num?)?.toDouble() ?? 0,
        perimeter: (json['perimeter'] as num?)?.toDouble() ?? 0,
      );
}

class SurfaceLoop {
  const SurfaceLoop({
    required this.id,
    required this.outer,
    required this.edgeIds,
  });
  final String id;
  final bool outer;
  final List<String> edgeIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'outer': outer,
    'edgeIds': edgeIds,
  };
  factory SurfaceLoop.fromJson(Map<String, dynamic> json) => SurfaceLoop(
    id: json['id'] as String,
    outer: json['outer'] as bool? ?? false,
    edgeIds: (json['edgeIds'] as List? ?? const []).cast<String>(),
  );
}

class SurfaceEdge {
  const SurfaceEdge({
    required this.id,
    required this.sourceEntityId,
    required this.vertexIds,
    required this.points,
    this.revision = 1,
  });
  final String id;
  final String sourceEntityId;
  final List<String> vertexIds;
  final List<List<double>> points;
  final int revision;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceEntityId': sourceEntityId,
    'vertexIds': vertexIds,
    'points': points,
    'revision': revision,
  };
  factory SurfaceEdge.fromJson(Map<String, dynamic> json) => SurfaceEdge(
    id: json['id'] as String,
    sourceEntityId: json['sourceEntityId'] as String,
    vertexIds: (json['vertexIds'] as List? ?? const []).cast<String>(),
    points: (json['points'] as List? ?? const [])
        .whereType<List>()
        .map((point) => point.cast<num>().map((v) => v.toDouble()).toList())
        .toList(),
    revision: json['revision'] as int? ?? 1,
  );
}

class SurfaceVertex {
  const SurfaceVertex({
    required this.id,
    required this.sourceKeys,
    required this.position,
    this.revision = 1,
  });
  final String id;
  final List<String> sourceKeys;
  final List<double> position;
  final int revision;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceKeys': sourceKeys,
    'position': position,
    'revision': revision,
  };
  factory SurfaceVertex.fromJson(Map<String, dynamic> json) => SurfaceVertex(
    id: json['id'] as String,
    sourceKeys: (json['sourceKeys'] as List? ?? const []).cast<String>(),
    position: (json['position'] as List)
        .cast<num>()
        .map((v) => v.toDouble())
        .toList(),
    revision: json['revision'] as int? ?? 1,
  );
}
