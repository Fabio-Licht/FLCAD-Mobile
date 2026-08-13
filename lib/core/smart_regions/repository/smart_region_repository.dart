import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../features/projects/data/project_repository.dart';
import '../events/region_event.dart';
import '../graph/region_graph.dart';
import '../models/region_layer.dart';
import '../models/smart_region.dart';
import '../serialization/smart_region_serializer.dart';

class SmartRegionRepository {
  SmartRegionRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;
  Future<Directory> _directory(String projectId) async {
    final project = await _projects.directoryFor(projectId);
    final dir = Directory(path.join(project.path, 'SmartRegions'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<List<SmartRegion>> loadRegions(String projectId) async {
    final file = File(
      path.join((await _directory(projectId)).path, 'smart_regions.json'),
    );
    if (!await file.exists()) return [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return (json['regions'] as List)
        .map((e) => SmartRegionSerializer.fromJson((e as Map).cast()))
        .toList();
  }

  Future<void> saveRegions(String projectId, List<SmartRegion> regions) =>
      _atomic(projectId, 'smart_regions.json', {
        'version': 1,
        'projectId': projectId,
        'regions': regions.map(SmartRegionSerializer.toJson).toList(),
      });
  Future<void> saveGraph(String projectId, RegionGraph graph) =>
      _atomic(projectId, 'region_graph.json', graph.toJson());
  Future<void> saveEvents(String projectId, List<RegionEvent> events) =>
      _atomic(projectId, 'region_history.json', {
        'version': 1,
        'events': events.map((e) => e.toJson()).toList(),
      });
  Future<void> saveLayers(
    String projectId,
    List<RegionLayer> layers,
    List<RegionGroup> groups,
  ) => _atomic(projectId, 'region_layers.json', {
    'version': 1,
    'layers': layers.map((e) => e.toJson()).toList(),
    'groups': groups.map((e) => e.toJson()).toList(),
  });
  Future<void> saveRules(String projectId, List<Map<String, dynamic>> rules) =>
      _atomic(projectId, 'region_rules.json', {'version': 1, 'rules': rules});
  Future<void> saveSnapshot(
    String projectId,
    String id,
    List<SmartRegion> regions,
  ) => _atomic(projectId, path.join('Snapshots', '$id.json'), {
    'version': 1,
    'createdAt': DateTime.now().toIso8601String(),
    'regions': regions.map(SmartRegionSerializer.toJson).toList(),
  });
  Future<void> _atomic(
    String projectId,
    String name,
    Map<String, dynamic> data,
  ) async {
    final file = File(path.join((await _directory(projectId)).path, name));
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }
}
