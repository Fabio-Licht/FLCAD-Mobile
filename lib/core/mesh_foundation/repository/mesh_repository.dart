import 'dart:convert';
import 'dart:io';
import '../analytics/mesh_analytics.dart';
import '../history/mesh_history.dart';
import '../models/mesh_models.dart';

class MeshRepository {
  MeshRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, MeshEntity> meshes = {};
  static const paths = [
    'CAD/Meshes',
    'CAD/MeshMetadata',
    'CAD/MeshStatistics',
    'CAD/MeshDiagnostics',
    'CAD/MeshHistory',
    'CAD/MeshAnalytics',
    'CAD/MeshValidation',
  ];
  Directory _dir(String p) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}',
  );
  void register(MeshEntity mesh) {
    if (meshes.containsKey(mesh.id)) {
      throw StateError('Duplicate mesh id: ${mesh.id}');
    }
    meshes[mesh.id] = mesh;
  }

  MeshEntity? find(String id) => meshes[id];
  MeshEntity remove(String id) =>
      meshes.remove(id) ?? (throw StateError('Unknown mesh: $id'));
  void rename(String id, String name) =>
      (meshes[id] ?? (throw StateError('Unknown mesh: $id'))).name = name;
  Map<String, dynamic> cloneMetadata(String id) => Map<String, dynamic>.from(
    (meshes[id] ?? (throw StateError('Unknown mesh: $id'))).toJson(),
  );
  Future<void> persist({
    required MeshAnalytics analytics,
    required MeshHistory history,
    required Map<String, List<MeshDiagnostic>> diagnostics,
  }) async {
    for (final p in paths) {
      await _dir(p).create(recursive: true);
    }
    for (final mesh in meshes.values) {
      final json = mesh.toJson(), name = mesh.id.replaceAll(':', '_');
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(json));
      await File(
        '${_dir(paths[1]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(json));
    }
    final diagnosticJson = diagnostics.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}statistics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}diagnostics.json',
    ).writeAsString(jsonEncode(diagnosticJson));
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    await File(
      '${_dir(paths[6]).path}${Platform.pathSeparator}validation.json',
    ).writeAsString(jsonEncode(diagnosticJson));
  }
}
