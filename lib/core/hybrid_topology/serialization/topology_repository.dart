import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../features/projects/data/project_repository.dart';
import '../constraints/topology_constraint.dart';
import '../graph/topology_graph.dart';
import '../hybrid/hybrid_object.dart';
import '../layers/mesh_layer.dart';
import '../workspace/local_workspace.dart';

class TopologyRepository {
  TopologyRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;
  Future<Directory> directory(String id) async {
    final root = await _projects.directoryFor(id),
        d = Directory(path.join(root.path, 'Topology'));
    await d.create(recursive: true);
    return d;
  }

  Future<void> saveTopology(String id, List<HybridObject> values) => _write(
    id,
    'topology.json',
    {'version': 1, 'objects': values.map(_object).toList()},
  );
  Future<void> saveLayers(String id, List<MeshLayer> values) => _write(
    id,
    'layers.json',
    {'version': 1, 'layers': values.map((e) => e.toJson()).toList()},
  );
  Future<void> saveWorkspaces(String id, List<LocalWorkspace> values) => _write(
    id,
    'workspace.json',
    {'version': 1, 'workspaces': values.map((e) => e.toJson()).toList()},
  );
  Future<void> saveConstraints(String id, List<TopologyConstraint> values) =>
      _write(id, 'constraints.json', {
        'version': 1,
        'constraints': values.map((e) => e.toJson()).toList(),
      });
  Future<void> saveHistory(String id, List<Map<String, dynamic>> values) =>
      _write(id, 'morph_history.json', {'version': 1, 'history': values});
  Future<void> saveGraph(String id, TopologyGraph graph) =>
      _write(id, 'graph.json', graph.toJson());
  Future<void> _write(String id, String name, Map<String, dynamic> j) async {
    final f = File(path.join((await directory(id)).path, name)),
        t = File('${f.path}.tmp');
    await t.writeAsString(
      const JsonEncoder.withIndent('  ').convert(j),
      flush: true,
    );
    if (await f.exists()) await f.delete();
    await t.rename(f.path);
  }

  Map<String, dynamic> _object(HybridObject o) => {
    'id': o.id,
    'projectId': o.projectId,
    'name': o.name,
    'mode': o.mode.name,
    'assets': o.assets.map((e) => e.toJson()).toList(),
    'regionIds': o.regionIds,
    'referenceIds': o.referenceIds,
    'sketchIds': o.sketchIds,
    'surfaceIds': o.surfaceIds,
    'solidIds': o.solidIds,
    'layerIds': o.layerIds,
    'dna': o.dna.toJson(),
    'analytics': o.analytics.toJson(),
    'version': o.version,
    'createdAt': o.createdAt.toIso8601String(),
    'updatedAt': o.updatedAt.toIso8601String(),
    'metadata': o.metadata,
  };
}
