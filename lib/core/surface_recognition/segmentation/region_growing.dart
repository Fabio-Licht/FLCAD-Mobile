import 'dart:math' as math;

import '../../cad_kernel/io/kernel_io_models.dart';
import '../../geometric_kernel/geometry/vectors.dart';
import '../models/surface_recognition_models.dart';

class RegionGrowingResult {
  const RegionGrowingResult(this.regions, this.graph);
  final List<SurfaceRegion> regions;
  final RegionGraph graph;
}

class ProfessionalRegionGrowing {
  const ProfessionalRegionGrowing();

  RegionGrowingResult segment(
    MeshSurfaceData mesh,
    String meshFingerprint, {
    SurfaceRecognitionSettings settings = const SurfaceRecognitionSettings(),
  }) {
    if (mesh.triangles.isEmpty) {
      return const RegionGrowingResult([], RegionGraph({}));
    }
    final normals = <Vector3>[], areas = <double>[];
    for (final triangle in mesh.triangles) {
      final a = mesh.vertices[triangle.$1],
          b = mesh.vertices[triangle.$2],
          c = mesh.vertices[triangle.$3];
      final cross = (b - a).cross(c - a);
      normals.add(cross.normalized);
      areas.add(cross.length * .5);
    }
    final adjacency = _triangleAdjacency(mesh.triangles);
    final curvature = List<double>.generate(normals.length, (i) {
      final neighbors = adjacency[i];
      if (neighbors.isEmpty) return 0;
      return neighbors
              .map((j) => _angle(normals[i], normals[j]))
              .reduce((a, b) => a + b) /
          neighbors.length;
    });
    final limit = settings.normalAngleDegrees * math.pi / 180;
    final visited = List<bool>.filled(mesh.triangles.length, false);
    final groups = <Set<int>>[];
    for (var seed = 0; seed < visited.length; seed++) {
      if (visited[seed]) continue;
      final group = <int>{seed}, queue = <int>[seed];
      visited[seed] = true;
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        for (final next in adjacency[current]) {
          if (visited[next] ||
              _angle(normals[current], normals[next]) > limit ||
              (curvature[current] - curvature[next]).abs() >
                  settings.curvatureDelta ||
              (curvature[seed] - curvature[next]).abs() >
                  settings.curvatureDelta) {
            continue;
          }
          visited[next] = true;
          group.add(next);
          queue.add(next);
        }
      }
      groups.add(group);
    }
    _mergeSmall(groups, adjacency, settings.minimumTriangles);
    groups.sort((a, b) => a.reduce(math.min).compareTo(b.reduce(math.min)));
    final triangleRegion = <int, int>{};
    for (var i = 0; i < groups.length; i++) {
      for (final triangle in groups[i]) {
        triangleRegion[triangle] = i;
      }
    }
    final graphEdges = <String, Set<String>>{};
    final regions = <SurfaceRegion>[];
    for (var i = 0; i < groups.length; i++) {
      final id = 'region:$meshFingerprint:${i + 1}';
      final triangles = groups[i].toList()..sort();
      final vertices = <int>{};
      var area = 0.0, normal = Vector3.zero, meanCurvature = 0.0;
      for (final index in triangles) {
        final t = mesh.triangles[index];
        vertices.addAll([t.$1, t.$2, t.$3]);
        area += areas[index];
        normal = normal + normals[index] * areas[index];
        meanCurvature += curvature[index];
      }
      final sortedVertices = vertices.toList()..sort();
      regions.add(
        SurfaceRegion(
          id: id,
          color: _color(i),
          triangleIndices: triangles,
          vertexIndices: sortedVertices,
          area: area,
          averageNormal: normal.normalized,
          bounds: _bounds(sortedVertices.map((v) => mesh.vertices[v]).toList()),
          meanCurvature: meanCurvature / triangles.length,
          confidence: math.min(1, .55 + math.log(triangles.length + 1) / 15),
          health: triangles.length >= settings.minimumTriangles
              ? RecognitionHealth.good
              : RecognitionHealth.low,
        ),
      );
      graphEdges[id] = <String>{};
    }
    for (var i = 0; i < adjacency.length; i++) {
      for (final j in adjacency[i]) {
        final a = triangleRegion[i]!, b = triangleRegion[j]!;
        if (a != b) {
          graphEdges[regions[a].id]!.add(regions[b].id);
          graphEdges[regions[b].id]!.add(regions[a].id);
        }
      }
    }
    return RegionGrowingResult(regions, RegionGraph(graphEdges));
  }

  List<Set<int>> _triangleAdjacency(List<(int, int, int)> triangles) {
    final edgeOwners = <(int, int), List<int>>{};
    for (var i = 0; i < triangles.length; i++) {
      final t = triangles[i];
      for (final edge in [(t.$1, t.$2), (t.$2, t.$3), (t.$3, t.$1)]) {
        final key = edge.$1 < edge.$2 ? edge : (edge.$2, edge.$1);
        edgeOwners.putIfAbsent(key, () => []).add(i);
      }
    }
    final result = List.generate(triangles.length, (_) => <int>{});
    for (final owners in edgeOwners.values) {
      for (final a in owners) {
        for (final b in owners) {
          if (a != b) result[a].add(b);
        }
      }
    }
    return result;
  }

  void _mergeSmall(
    List<Set<int>> groups,
    List<Set<int>> adjacency,
    int minimum,
  ) {
    final owner = <int, int>{};
    for (var group = 0; group < groups.length; group++) {
      for (final triangle in groups[group]) {
        owner[triangle] = group;
      }
    }
    final active = List<bool>.filled(groups.length, true);
    var changed = true;
    while (changed) {
      changed = false;
      for (var i = groups.length - 1; i >= 0; i--) {
        if (!active[i] || groups[i].length >= minimum) continue;
        final contactsByGroup = <int, int>{};
        for (final triangle in groups[i]) {
          for (final neighbor in adjacency[triangle]) {
            final candidate = owner[neighbor];
            if (candidate != null && candidate != i && active[candidate]) {
              contactsByGroup[candidate] =
                  (contactsByGroup[candidate] ?? 0) + 1;
            }
          }
        }
        var best = -1, contacts = -1;
        final candidates = contactsByGroup.keys.toList()..sort();
        for (final j in candidates) {
          final count = contactsByGroup[j]!;
          if (count > contacts) {
            best = j;
            contacts = count;
          }
        }
        if (best >= 0 && contacts > 0) {
          groups[best].addAll(groups[i]);
          for (final triangle in groups[i]) {
            owner[triangle] = best;
          }
          groups[i].clear();
          active[i] = false;
          changed = true;
        }
      }
    }
    groups.removeWhere((group) => group.isEmpty);
  }

  double _angle(Vector3 a, Vector3 b) =>
      math.acos(a.dot(b).abs().clamp(-1.0, 1.0));
  String _color(int i) {
    const colors = [
      '#2196F3',
      '#F44336',
      '#4CAF50',
      '#FF9800',
      '#9C27B0',
      '#00BCD4',
      '#CDDC39',
      '#795548',
      '#E91E63',
      '#607D8B',
    ];
    return colors[i % colors.length];
  }

  KernelBounds _bounds(List<Vector3> p) {
    var minX = p.first.x,
        minY = p.first.y,
        minZ = p.first.z,
        maxX = minX,
        maxY = minY,
        maxZ = minZ;
    for (final v in p.skip(1)) {
      minX = math.min(minX, v.x);
      minY = math.min(minY, v.y);
      minZ = math.min(minZ, v.z);
      maxX = math.max(maxX, v.x);
      maxY = math.max(maxY, v.y);
      maxZ = math.max(maxZ, v.z);
    }
    return KernelBounds(minX, minY, minZ, maxX, maxY, maxZ);
  }
}
