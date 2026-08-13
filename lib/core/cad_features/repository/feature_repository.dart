import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../graph/feature_graph.dart';
import '../models/feature_models.dart';

class FeatureRepository {
  const FeatureRepository(this.projectDirectory);
  final Directory projectDirectory;
  Directory get features =>
      Directory(path.join(projectDirectory.path, 'CAD', 'Features'));
  Directory get history =>
      Directory(path.join(projectDirectory.path, 'CAD', 'History'));
  Directory get graph =>
      Directory(path.join(projectDirectory.path, 'CAD', 'FeatureGraph'));
  Future<void> initialize() async {
    await features.create(recursive: true);
    await history.create(recursive: true);
    await graph.create(recursive: true);
  }

  Future<void> save(CadFeature feature) async {
    await initialize();
    final target = File(path.join(features.path, '${feature.id}.json'));
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsString(jsonEncode(feature.toJson()), flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temporary.rename(target.path);
    await File(path.join(history.path, 'events.jsonl')).writeAsString(
      '${jsonEncode(feature.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<void> saveGraph(FeatureGraph value) async {
    await initialize();
    await File(
      path.join(graph.path, 'feature_graph.json'),
    ).writeAsString(jsonEncode(value.toJson()), flush: true);
  }

  Future<List<CadFeature>> loadAll() async {
    await initialize();
    final result = <CadFeature>[];
    await for (final item in features.list()) {
      if (item is File && item.path.endsWith('.json')) {
        result.add(
          CadFeature.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(await item.readAsString()) as Map,
            ),
          ),
        );
      }
    }
    return result;
  }
}
