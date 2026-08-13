import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../features/projects/data/project_repository.dart';
import '../graph/reference_graph.dart';
import '../models/reference_entity.dart';
import '../serialization/reference_serializer.dart';

class ReferenceRepository {
  ReferenceRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;
  Future<Directory> directory(String projectId) async {
    final p = await _projects.directoryFor(projectId),
        d = Directory(path.join(p.path, 'References'));
    await d.create(recursive: true);
    return d;
  }

  Future<List<ReferenceEntity>> load(String projectId) async {
    final f = File(
      path.join((await directory(projectId)).path, 'references.json'),
    );
    if (!await f.exists()) return [];
    final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    return (j['references'] as List)
        .map((e) => ReferenceSerializer.fromJson((e as Map).cast()))
        .toList();
  }

  Future<void> save(String projectId, List<ReferenceEntity> refs) =>
      _atomic(projectId, 'references.json', {
        'version': 1,
        'projectId': projectId,
        'references': refs.map(ReferenceSerializer.toJson).toList(),
      });
  Future<void> saveGraph(String projectId, ReferenceGraph graph) =>
      _atomic(projectId, 'reference_graph.json', graph.toJson());
  Future<ReferenceGraph> loadGraph(String projectId) async {
    final file = File(
      path.join((await directory(projectId)).path, 'reference_graph.json'),
    );
    if (!await file.exists()) return ReferenceGraph();
    return ReferenceGraph.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  Future<void> saveHistory(
    String projectId,
    List<Map<String, dynamic>> history,
  ) => _atomic(projectId, 'reference_history.json', {
    'version': 1,
    'history': history,
  });
  Future<void> saveSnapshot(
    String projectId,
    String id,
    List<ReferenceEntity> refs,
  ) => _atomic(projectId, path.join('Snapshots', '$id.json'), {
    'version': 1,
    'references': refs.map(ReferenceSerializer.toJson).toList(),
  });
  Future<void> _atomic(String p, String name, Map<String, dynamic> data) async {
    final f = File(path.join((await directory(p)).path, name)),
        t = File('${f.path}.tmp');
    await f.parent.create(recursive: true);
    await t.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    if (await f.exists()) await f.delete();
    await t.rename(f.path);
  }
}
