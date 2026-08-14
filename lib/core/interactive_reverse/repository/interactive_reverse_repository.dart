import 'dart:convert';
import 'dart:io';
import '../analytics/interactive_analytics.dart';
import '../history/interactive_history.dart';
import '../models/interactive_models.dart';

class InteractiveReverseRepository {
  InteractiveReverseRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Selections',
    'CAD/SelectionHistory',
    'CAD/SelectionAnalytics',
    'CAD/SelectionPreview',
    'CAD/InteractiveWorkspace',
    'CAD/ContextActions',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String value) => value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<InteractiveSelection> selections,
    required Iterable<SelectionPreview> previews,
    required Iterable<InteractionIntent> intents,
    required InteractiveHistory history,
    required InteractiveTimeline timeline,
    required InteractiveAnalytics analytics,
    required InteractiveDashboardState dashboard,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final selection in selections) {
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}${_safe(selection.id)}.json',
      ).writeAsString(jsonEncode(selection.toJson()));
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}timeline.json',
    ).writeAsString(
      jsonEncode(timeline.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    for (final preview in previews) {
      await File(
        '${_dir(paths[3]).path}${Platform.pathSeparator}${_safe(preview.selectionId)}.json',
      ).writeAsString(jsonEncode(preview.toJson()));
    }
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}dashboard.json',
    ).writeAsString(jsonEncode(dashboard.toJson()));
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}actions.json',
    ).writeAsString(jsonEncode(intents.map((e) => e.toJson()).toList()));
  }
}

class InteractiveReverseRepositoryFactory {
  const InteractiveReverseRepositoryFactory();
  InteractiveReverseRepository create(Directory project) =>
      InteractiveReverseRepository(project);
}
