import 'dart:math' as math;

import '../models/geometry.dart';
import '../models/region_dna.dart';
import '../models/region_statistics.dart';
import '../selection/triangle_selection.dart';

class RegionAnalysis {
  const RegionAnalysis(this.statistics, this.dna, this.bounds);
  final RegionStatistics statistics;
  final RegionDNA dna;
  final BoundingBox bounds;
}

class RegionAnalyticsEngine {
  const RegionAnalyticsEngine();
  RegionAnalysis analyze(MeshTopology mesh, TriangleSelection selection) {
    if (selection.length == 0) throw ArgumentError('Region cannot be empty');
    var area = 0.0,
        normalSum = const Vec3(0, 0, 0),
        centroidSum = const Vec3(0, 0, 0),
        curvature = 0.0;
    final vertices = <int>{};
    final normalBins = List.filled(8, 0.0);
    final curveBins = List.filled(8, 0.0);
    var perimeter = 0.0;
    var components = 0;
    var minX = double.infinity,
        minY = double.infinity,
        minZ = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity,
        maxZ = -double.infinity;
    for (final i in selection.indices) {
      final t = mesh.triangles[i],
          a = mesh.triangleArea(i),
          n = mesh.triangleNormal(i);
      area += a;
      normalSum = normalSum + n;
      vertices.addAll([t.a, t.b, t.c]);
      final c =
          (mesh.vertices[t.a] + mesh.vertices[t.b] + mesh.vertices[t.c]) / 3;
      centroidSum = centroidSum + c;
      normalBins[((n.z + 1) * 3.999).floor().clamp(0, 7)]++;
      for (final v in [
        mesh.vertices[t.a],
        mesh.vertices[t.b],
        mesh.vertices[t.c],
      ]) {
        minX = math.min(minX, v.x);
        minY = math.min(minY, v.y);
        minZ = math.min(minZ, v.z);
        maxX = math.max(maxX, v.x);
        maxY = math.max(maxY, v.y);
        maxZ = math.max(maxZ, v.z);
      }
      final inside = mesh.triangleNeighbors[i]
          .where(selection.contains)
          .toList();
      if (inside.isEmpty) components++;
      for (final neighbor in inside) {
        curvature +=
            1 - mesh.triangleNormal(i).dot(mesh.triangleNormal(neighbor)).abs();
      }
      perimeter += 3 - inside.length;
    }
    final count = selection.length,
        avgNormal = (normalSum / count.toDouble()).normalized,
        centroid = centroidSum / count.toDouble();
    final avgCurvature = curvature / math.max(1, count);
    curveBins[(avgCurvature * 7).floor().clamp(0, 7)] = count.toDouble();
    final type = avgCurvature < .03
        ? 'plane'
        : avgCurvature < .25
        ? 'cylinder_or_cone'
        : 'organic';
    final statistics = RegionStatistics(
      area: area,
      perimeter: perimeter,
      estimatedVolume: 0.0,
      averageCurvature: avgCurvature,
      averageNormal: avgNormal,
      dominantType: type,
      angularDistribution: normalBins,
      connectivity: components,
      triangleCount: count,
      vertexCount: vertices.length,
      density: count / math.max(area, 1e-9),
      centroid: centroid,
    );
    final signature = '$count:${vertices.length}:$components:$type';
    final raw = '$signature:${area.toStringAsFixed(6)}:${centroid.toJson()}';
    final hash = raw.codeUnits
        .fold<int>(17, (a, b) => 37 * a + b)
        .toUnsigned(32)
        .toRadixString(16);
    final dna = RegionDNA(
      normalHistogram: _normalize(normalBins),
      curvatureHistogram: _normalize(curveBins),
      topologySignature: signature,
      area: area,
      perimeter: perimeter,
      connectivity: components,
      centroid: centroid.toJson(),
      hash: hash,
    );
    return RegionAnalysis(
      statistics,
      dna,
      BoundingBox(Vec3(minX, minY, minZ), Vec3(maxX, maxY, maxZ)),
    );
  }

  List<double> _normalize(List<double> values) {
    final sum = values.fold<double>(0, (a, b) => a + b);
    return sum == 0 ? values : values.map((v) => v / sum).toList();
  }
}
