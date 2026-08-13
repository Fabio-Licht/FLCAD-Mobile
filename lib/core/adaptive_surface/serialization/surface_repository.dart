import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../features/projects/data/project_repository.dart';
import '../graph/surface_graph.dart';
import '../models/adaptive_surface.dart';
import 'surface_serializer.dart';

class SurfaceRepository {
  SurfaceRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;
  Future<Directory> directory(String id) async {
    final root = await _projects.directoryFor(id),
        d = Directory(path.join(root.path, 'Surfaces'));
    await d.create(recursive: true);
    return d;
  }

  Future<List<AdaptiveSurface>> load(String id) async {
    final file = File(path.join((await directory(id)).path, 'surfaces.json'));
    if (!await file.exists()) return [];
    final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return (j['surfaces'] as List)
        .map((v) => SurfaceSerializer.fromJson((v as Map).cast()))
        .toList();
  }

  Future<void> save(String id, List<AdaptiveSurface> values) =>
      _atomic(id, 'surfaces.json', {
        'version': 1,
        'projectId': id,
        'surfaces': values.map(SurfaceSerializer.toJson).toList(),
      });
  Future<SurfaceGraph> loadGraph(String id) async {
    final file = File(
      path.join((await directory(id)).path, 'surface_graph.json'),
    );
    return await file.exists()
        ? SurfaceGraph.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          )
        : SurfaceGraph();
  }

  Future<void> saveGraph(String id, SurfaceGraph graph) =>
      _atomic(id, 'surface_graph.json', graph.toJson());
  Future<void> saveHistory(String id, List<Map<String, dynamic>> values) =>
      _atomic(id, 'surface_history.json', {'version': 1, 'history': values});
  Future<void> saveNetwork(String id, Map<String, dynamic> value) =>
      _atomic(id, 'surface_network.json', {'version': 1, ...value});
  Future<void> saveSnapshot(String id, String name, AdaptiveSurface value) =>
      _atomic(id, path.join('Snapshots', '$name.json'), {
        'version': 1,
        'surface': SurfaceSerializer.toJson(value),
      });
  Future<void> _atomic(String id, String name, Map<String, dynamic> j) async {
    final file = File(path.join((await directory(id)).path, name)),
        temp = File('${file.path}.tmp');
    await file.parent.create(recursive: true);
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(j),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }
}
