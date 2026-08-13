import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../features/projects/data/project_repository.dart';
import '../features/engineering_feature.dart';
import '../graph/feature_graph.dart';
import '../solids/engineering_solid.dart';
import '../timeline/engineering_timeline.dart';

class ParametricRepository {
  ParametricRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;
  Future<Directory> directory(String id) async {
    final root = await _projects.directoryFor(id),
        d = Directory(path.join(root.path, 'Features'));
    await d.create(recursive: true);
    return d;
  }

  Future<void> saveFeatures(String id, List<EngineeringFeature> values) =>
      _write(id, 'features.json', {
        'version': 1,
        'features': values.map(_feature).toList(),
      });
  Future<void> saveGraph(String id, FeatureGraph graph) =>
      _write(id, 'feature_graph.json', graph.toJson());
  Future<void> saveHistory(String id, List<Map<String, dynamic>> history) =>
      _write(id, 'engineering_history.json', {
        'version': 1,
        'history': history,
      });
  Future<void> saveTimeline(String id, EngineeringTimeline t) =>
      _write(id, 'timeline.json', {
        'version': 1,
        'branches': t.branches.values.map((e) => e.toJson()).toList(),
        'decisions': t.decisions.map((e) => e.toJson()).toList(),
      });
  Future<void> saveSolids(String id, List<EngineeringSolid> solids) => _write(
    id,
    'solid.json',
    {'version': 1, 'solids': solids.map((e) => e.toJson()).toList()},
  );
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

  Map<String, dynamic> _feature(EngineeringFeature f) => {
    'id': f.id,
    'projectId': f.projectId,
    'name': f.name,
    'kind': f.kind.name,
    'mode': f.mode.name,
    'status': f.status.name,
    'parameters': f.parameters,
    'sourceIds': f.sourceIds,
    'dependencyIds': f.dependencyIds,
    'referenceIds': f.referenceIds,
    'intent': f.intent,
    'manufacturing': f.manufacturing.name,
    'inspection': f.inspection.name,
    'dna': f.dna.toJson(),
    'version': f.version,
    'createdAt': f.createdAt.toIso8601String(),
    'updatedAt': f.updatedAt.toIso8601String(),
    'kernelResultId': f.kernelResultId,
    'metadata': f.metadata,
  };
}
