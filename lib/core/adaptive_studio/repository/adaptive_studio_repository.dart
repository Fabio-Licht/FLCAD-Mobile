import 'dart:convert';
import 'dart:io';
import '../analytics/workspace_analytics.dart';
import '../history/workspace_history.dart';
import '../models/adaptive_studio_models.dart';

class AdaptiveStudioRepository {
  AdaptiveStudioRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Workspace',
    'CAD/Layout',
    'CAD/Dashboard',
    'CAD/Docking',
    'CAD/Navigation',
    'CAD/WorkspaceAnalytics',
    'CAD/WorkspaceMemory',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<AdaptiveWorkspaceState> workspaces,
    required Iterable<WorkspaceMemory> memories,
    required WorkspaceHistory history,
    required WorkspaceAnalytics analytics,
    required Iterable<StudioNotification> notifications,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final state in workspaces) {
      final name = _safe(state.id), json = state.toJson();
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(json));
      await File(
        '${_dir(paths[1]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(
        jsonEncode({
          'panels': json['panels'],
          'ribbon': json['ribbon'],
          'toolbars': json['toolbars'],
        }),
      );
      await File(
        '${_dir(paths[2]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(state.dashboard.toJson()));
      await File(
        '${_dir(paths[3]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(
        jsonEncode(state.panels.map((k, v) => MapEntry(k, v.dockState.name))),
      );
      await File(
        '${_dir(paths[4]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(state.navigation.toJson()));
    }
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}notifications.json',
    ).writeAsString(jsonEncode(notifications.map((e) => e.toJson()).toList()));
    for (final memory in memories) {
      await File(
        '${_dir(paths[6]).path}${Platform.pathSeparator}${_safe(memory.id)}.json',
      ).writeAsString(jsonEncode(memory.toJson()));
    }
  }
}

class AdaptiveStudioRepositoryFactory {
  const AdaptiveStudioRepositoryFactory();
  AdaptiveStudioRepository create(Directory project) =>
      AdaptiveStudioRepository(project);
}
