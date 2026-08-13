import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../features/projects/data/project_repository.dart';
import '../graph/sketch_graph.dart';
import '../models/sketch.dart';
import 'sketch_serializer.dart';

class SketchRepository {
  SketchRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;
  Future<Directory> directory(String projectId) async {
    final root = await _projects.directoryFor(projectId),
        result = Directory(path.join(root.path, 'Sketch'));
    await result.create(recursive: true);
    return result;
  }

  Future<List<IntelligentSketch>> load(String projectId) async {
    final file = File(
      path.join((await directory(projectId)).path, 'sketches.json'),
    );
    if (!await file.exists()) return [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return (json['sketches'] as List)
        .map((e) => SketchSerializer.fromJson((e as Map).cast()))
        .toList();
  }

  Future<void> save(String projectId, List<IntelligentSketch> values) =>
      _atomic(projectId, 'sketches.json', {
        'version': 1,
        'projectId': projectId,
        'sketches': values.map(SketchSerializer.toJson).toList(),
      });
  Future<SketchGraph> loadGraph(String projectId) async {
    final file = File(
      path.join((await directory(projectId)).path, 'sketch_graph.json'),
    );
    return await file.exists()
        ? SketchGraph.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          )
        : SketchGraph();
  }

  Future<void> saveGraph(String id, SketchGraph graph) =>
      _atomic(id, 'sketch_graph.json', graph.toJson());
  Future<void> saveHistory(String id, List<Map<String, dynamic>> values) =>
      _atomic(id, 'sketch_history.json', {'version': 1, 'history': values});
  Future<void> saveConstraints(String id, List<IntelligentSketch> values) =>
      _atomic(id, 'constraints.json', {
        'version': 1,
        'constraints': values
            .expand(
              (s) =>
                  s.constraints.map((c) => {'sketchId': s.id, ...c.toJson()}),
            )
            .toList(),
      });
  Future<void> saveSnapshot(String id, String name, IntelligentSketch value) =>
      _atomic(id, path.join('Snapshots', '$name.json'), {
        'version': 1,
        'sketch': SketchSerializer.toJson(value),
      });
  Future<void> _atomic(
    String id,
    String name,
    Map<String, dynamic> json,
  ) async {
    final file = File(path.join((await directory(id)).path, name)),
        temporary = File('${file.path}.tmp');
    await file.parent.create(recursive: true);
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }
}
