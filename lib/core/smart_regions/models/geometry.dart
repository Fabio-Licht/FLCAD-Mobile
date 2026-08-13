import 'dart:math' as math;

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;
  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator /(double value) => Vec3(x / value, y / value, z / value);
  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;
  Vec3 cross(Vec3 other) => Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );
  double get length => math.sqrt(dot(this));
  Vec3 get normalized => length == 0 ? const Vec3(0, 0, 0) : this / length;
  List<double> toJson() => [x, y, z];
  factory Vec3.fromJson(List<dynamic> value) => Vec3(
    (value[0] as num).toDouble(),
    (value[1] as num).toDouble(),
    (value[2] as num).toDouble(),
  );
}

class BoundingBox {
  const BoundingBox(this.min, this.max);
  final Vec3 min, max;
  Map<String, dynamic> toJson() => {'min': min.toJson(), 'max': max.toJson()};
  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
    Vec3.fromJson(json['min'] as List),
    Vec3.fromJson(json['max'] as List),
  );
}

class Triangle {
  const Triangle(this.a, this.b, this.c);
  final int a, b, c;
  List<int> toJson() => [a, b, c];
  factory Triangle.fromJson(List<dynamic> value) =>
      Triangle(value[0] as int, value[1] as int, value[2] as int);
}

class MeshTopology {
  MeshTopology({
    required this.id,
    required List<Vec3> vertices,
    required List<Triangle> triangles,
  }) : vertices = List.unmodifiable(vertices),
       triangles = List.unmodifiable(triangles);
  final String id;
  final List<Vec3> vertices;
  final List<Triangle> triangles;
  late final List<Set<int>> triangleNeighbors = _buildNeighbors();
  List<Set<int>> _buildNeighbors() {
    final byEdge = <String, List<int>>{};
    for (var i = 0; i < triangles.length; i++) {
      final t = triangles[i];
      for (final edge in [(t.a, t.b), (t.b, t.c), (t.c, t.a)]) {
        final a = math.min(edge.$1, edge.$2), b = math.max(edge.$1, edge.$2);
        (byEdge['$a:$b'] ??= []).add(i);
      }
    }
    final result = List.generate(triangles.length, (_) => <int>{});
    for (final linked in byEdge.values) {
      for (final a in linked) {
        for (final b in linked) {
          if (a != b) result[a].add(b);
        }
      }
    }
    return result;
  }

  Vec3 triangleNormal(int index) {
    final t = triangles[index];
    return (vertices[t.b] - vertices[t.a])
        .cross(vertices[t.c] - vertices[t.a])
        .normalized;
  }

  double triangleArea(int index) {
    final t = triangles[index];
    return (vertices[t.b] - vertices[t.a])
            .cross(vertices[t.c] - vertices[t.a])
            .length /
        2;
  }
}
