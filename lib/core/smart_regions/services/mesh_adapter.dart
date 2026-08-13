import 'dart:convert';
import 'dart:io';
import '../models/geometry.dart';

abstract interface class MeshAdapter {
  Future<MeshTopology> load(String meshId, String path);
}

class AlphaJsonMeshAdapter implements MeshAdapter {
  @override
  Future<MeshTopology> load(String meshId, String path) async {
    final json =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    return MeshTopology(
      id: meshId,
      vertices: (json['vertices'] as List)
          .map((v) => Vec3.fromJson(v as List))
          .toList(),
      triangles: (json['faces'] as List)
          .map((f) => Triangle.fromJson(f as List))
          .toList(),
    );
  }
}
