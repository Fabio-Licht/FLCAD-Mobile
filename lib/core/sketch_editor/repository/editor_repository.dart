import 'dart:convert';
import 'dart:io';
import '../analytics/editor_analytics.dart';
import '../graph/editor_graph.dart';
import '../history/editor_history.dart';

class EditorRepository {
  EditorRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/SketchEditor',
    'CAD/SketchEditorHistory',
    'CAD/SketchEditorGraph',
    'CAD/SketchEditorAnalytics',
  ];
  Directory _dir(String p) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}',
  );
  Future<void> save({
    required EditorHistory history,
    required EditorGraph graph,
    required EditorAnalytics analytics,
  }) async {
    for (final p in paths) {
      await _dir(p).create(recursive: true);
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}graph.json',
    ).writeAsString(jsonEncode(graph.toJson()));
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
  }
}

class EditorRepositoryFactory {
  const EditorRepositoryFactory();
  EditorRepository create(Directory project) => EditorRepository(project);
}
