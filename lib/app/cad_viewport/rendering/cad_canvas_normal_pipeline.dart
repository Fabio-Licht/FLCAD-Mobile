import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/geometric_kernel/geometry/vectors.dart';

class CadCanvasNormalChunk {
  const CadCanvasNormalChunk({
    required this.xyz,
    required this.indices,
    required this.normals,
  });

  final Float64List xyz;
  final Uint16List indices;
  final Float32List normals;
}

/// Reconstructs one crease-aware normal per triangle corner.
///
/// Corner normals allow the same geometric vertex to remain smooth inside a
/// continuous region and discontinuous across a hard edge. Angle weighting
/// reduces tessellation bias; the square-root area term prevents tiny scan
/// triangles from dominating without letting a single large triangle erase
/// local shape.
abstract final class CadCanvasNormalPipeline {
  static List<CadCanvasNormalChunk> build(
    List<num> nodes,
    List<num> triangles, {
    double creaseAngleRadians = 50 * math.pi / 180,
    int trianglesPerChunk = 20000,
  }) {
    final vertexCount = nodes.length ~/ 3;
    final faceCount = triangles.length ~/ 3;
    final faceNormals = List<Vector3>.filled(faceCount, Vector3.zero);
    final faceArea2 = Float64List(faceCount);
    final cornerAngles = Float64List(faceCount * 3);

    Vector3 vertex(int index) {
      final offset = index * 3;
      return Vector3(
        nodes[offset].toDouble(),
        nodes[offset + 1].toDouble(),
        nodes[offset + 2].toDouble(),
      );
    }

    double angle(Vector3 first, Vector3 second) {
      final denominator = first.length * second.length;
      if (denominator <= 1e-20) return 0;
      return math.acos((first.dot(second) / denominator).clamp(-1.0, 1.0));
    }

    var minimum = vertexCount == 0 ? Vector3.zero : vertex(0);
    var maximum = minimum;
    for (var index = 1; index < vertexCount; index++) {
      final point = vertex(index);
      minimum = Vector3(
        math.min(minimum.x, point.x),
        math.min(minimum.y, point.y),
        math.min(minimum.z, point.z),
      );
      maximum = Vector3(
        math.max(maximum.x, point.x),
        math.max(maximum.y, point.y),
        math.max(maximum.z, point.z),
      );
    }
    final weldTolerance = math.max((maximum - minimum).length * 1e-7, 1e-9);
    final weldedGroup = Int32List(vertexCount);
    final groups = <(int, int, int), int>{};
    for (var index = 0; index < vertexCount; index++) {
      final point = vertex(index);
      final key = (
        (point.x / weldTolerance).round(),
        (point.y / weldTolerance).round(),
        (point.z / weldTolerance).round(),
      );
      weldedGroup[index] = groups.putIfAbsent(key, () => groups.length);
    }
    final incident = List.generate(groups.length, (_) => <int>[]);

    for (var face = 0; face < faceCount; face++) {
      final offset = face * 3;
      final ia = triangles[offset].toInt();
      final ib = triangles[offset + 1].toInt();
      final ic = triangles[offset + 2].toInt();
      final a = vertex(ia), b = vertex(ib), c = vertex(ic);
      final ab = b - a, ac = c - a;
      final cross = ab.cross(ac);
      final area2 = cross.length;
      faceArea2[face] = area2;
      faceNormals[face] = area2 <= 1e-20 ? Vector3.zero : cross / area2;
      cornerAngles[offset] = angle(ab, ac);
      cornerAngles[offset + 1] = angle(a - b, c - b);
      cornerAngles[offset + 2] = angle(a - c, b - c);
      if (ia >= 0 && ia < vertexCount) incident[weldedGroup[ia]].add(face);
      if (ib >= 0 && ib < vertexCount) incident[weldedGroup[ib]].add(face);
      if (ic >= 0 && ic < vertexCount) incident[weldedGroup[ic]].add(face);
    }

    final creaseCosine = math.cos(creaseAngleRadians);
    Vector3 cornerNormal(int face, int corner, int vertexIndex) {
      final reference = faceNormals[face];
      if (reference.length <= 1e-20) return const Vector3(0, 0, 1);
      var sum = Vector3.zero;
      final group = weldedGroup[vertexIndex];
      for (final neighbor in incident[group]) {
        final candidate = faceNormals[neighbor];
        if (candidate.length <= 1e-20 ||
            reference.dot(candidate) < creaseCosine) {
          continue;
        }
        final neighborOffset = neighbor * 3;
        var neighborCorner = 0;
        if (weldedGroup[triangles[neighborOffset + 1].toInt()] == group) {
          neighborCorner = 1;
        } else if (weldedGroup[triangles[neighborOffset + 2].toInt()] ==
            group) {
          neighborCorner = 2;
        }
        final weight =
            cornerAngles[neighborOffset + neighborCorner] *
            math.sqrt(math.max(faceArea2[neighbor], 1e-20));
        sum = sum + candidate * weight;
      }
      return sum.length <= 1e-20 ? reference : sum.normalized;
    }

    final chunks = <CadCanvasNormalChunk>[];
    for (
      var firstFace = 0;
      firstFace < faceCount;
      firstFace += trianglesPerChunk
    ) {
      final endFace = math.min(firstFace + trianglesPerChunk, faceCount);
      final xyz = Float64List((endFace - firstFace) * 9);
      final normals = Float32List((endFace - firstFace) * 9);
      final indices = Uint16List((endFace - firstFace) * 3);
      var outputVertex = 0;
      for (var face = firstFace; face < endFace; face++) {
        for (var corner = 0; corner < 3; corner++) {
          final global = triangles[face * 3 + corner].toInt();
          final point = vertex(global);
          final normal = cornerNormal(face, corner, global);
          final offset = outputVertex * 3;
          xyz[offset] = point.x;
          xyz[offset + 1] = point.y;
          xyz[offset + 2] = point.z;
          normals[offset] = normal.x;
          normals[offset + 1] = normal.y;
          normals[offset + 2] = normal.z;
          indices[outputVertex] = outputVertex;
          outputVertex++;
        }
      }
      chunks.add(
        CadCanvasNormalChunk(xyz: xyz, indices: indices, normals: normals),
      );
    }
    return chunks;
  }
}
