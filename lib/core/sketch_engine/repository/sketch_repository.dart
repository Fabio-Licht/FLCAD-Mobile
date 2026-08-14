import 'dart:convert';
import 'dart:io';

import '../analytics/sketch_analytics.dart';
import '../entities/sketch_entities.dart';
import '../graph/sketch_graph.dart';
import '../history/sketch_history.dart';
import '../models/sketch_models.dart';

class SketchRepository {
  SketchRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Sketch',
    'CAD/SketchEntities',
    'CAD/SketchHistory',
    'CAD/SketchGraph',
    'CAD/SketchAnalytics',
  ];
  Directory _directory(String relative) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safeName(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> initialize() async {
    for (final path in paths) {
      await _directory(path).create(recursive: true);
    }
  }

  Future<void> saveSketch(Sketch sketch) async {
    await initialize();
    await File(
      '${_directory(paths[0]).path}${Platform.pathSeparator}${_safeName(sketch.id)}.json',
    ).writeAsString(jsonEncode(sketch.toJson()));
  }

  Future<void> saveEntity(String sketchId, SketchEntity entity) async {
    await initialize();
    final dir = Directory(
      '${_directory(paths[1]).path}${Platform.pathSeparator}${_safeName(sketchId)}',
    );
    await dir.create(recursive: true);
    await File(
      '${dir.path}${Platform.pathSeparator}${_safeName(entity.id)}.json',
    ).writeAsString(jsonEncode(entity.toJson()));
  }

  Future<List<Sketch>> loadSketches() async {
    final dir = _directory(paths[0]);
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final result = <Sketch>[];
    for (final f in files) {
      result.add(
        Sketch.fromJson(
          (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>(),
        ),
      );
    }
    return result;
  }

  Future<List<SketchEntity>> loadEntities(String sketchId) async {
    final dir = Directory(
      '${_directory(paths[1]).path}${Platform.pathSeparator}${_safeName(sketchId)}',
    );
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final result = <SketchEntity>[];
    for (final f in files) {
      result.add(
        SketchEntity.fromJson(
          (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>(),
        ),
      );
    }
    return result;
  }

  Future<void> saveSupport({
    required SketchGraphSet graphs,
    required SketchHistory history,
    required SketchAnalytics analytics,
  }) async {
    await initialize();
    await File(
      '${_directory(paths[2]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_directory(paths[3]).path}${Platform.pathSeparator}graph.json',
    ).writeAsString(jsonEncode(graphs.toJson()));
    await File(
      '${_directory(paths[4]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
  }
}

class SketchRepositoryFactory {
  const SketchRepositoryFactory();
  SketchRepository create(Directory projectDirectory) =>
      SketchRepository(projectDirectory);
}
