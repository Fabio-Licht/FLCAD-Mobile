import 'dart:convert';
import 'dart:io';
import '../analytics/workflow_analytics.dart';
import '../history/workflow_history.dart';
import '../history/workflow_timeline.dart';
import '../models/workflow_models.dart';
import '../workflow/reverse_checklist.dart';

class WorkflowRepository {
  WorkflowRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Workflow',
    'CAD/WorkflowHistory',
    'CAD/WorkflowAnalytics',
    'CAD/WorkflowChecklist',
    'CAD/WorkflowTimeline',
    'CAD/WorkflowSnapshots',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<ReverseWorkflow> workflows,
    required WorkflowHistory history,
    required WorkflowAnalytics analytics,
    required WorkflowTimeline timeline,
    required Map<String, WorkflowSnapshot> snapshots,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final workflow in workflows) {
      final name = _safe(workflow.id);
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(workflow.toJson()));
      await File(
        '${_dir(paths[3]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(
        jsonEncode(
          const ReverseChecklist()
              .build(workflow)
              .map((e) => e.toJson())
              .toList(),
        ),
      );
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}timeline.json',
    ).writeAsString(
      jsonEncode(timeline.entries.map((e) => e.toJson()).toList()),
    );
    for (final snapshot in snapshots.values) {
      await File(
        '${_dir(paths[5]).path}${Platform.pathSeparator}${_safe(snapshot.id)}.json',
      ).writeAsString(jsonEncode(snapshot.toJson()));
    }
  }
}

class WorkflowRepositoryFactory {
  const WorkflowRepositoryFactory();
  WorkflowRepository create(Directory project) => WorkflowRepository(project);
}
