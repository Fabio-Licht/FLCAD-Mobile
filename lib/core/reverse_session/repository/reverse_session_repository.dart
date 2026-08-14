import 'dart:convert';
import 'dart:io';
import '../analytics/session_analytics.dart';
import '../models/session_models.dart';

class ReverseSessionRepository {
  ReverseSessionRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Sessions',
    'CAD/SessionSnapshots',
    'CAD/SessionJournal',
    'CAD/SessionTimeline',
    'CAD/SessionAnalytics',
    'CAD/SessionRecovery',
    'CAD/SessionMilestones',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<ReverseSession> sessions,
    required Iterable<SessionSnapshot> snapshots,
    required Iterable<SessionJournalEntry> journal,
    required Iterable<SessionJournalEntry> timeline,
    required Iterable<RecoveryState> recovery,
    required Iterable<SessionMilestone> milestones,
    required SessionAnalytics analytics,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final session in sessions) {
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}${_safe(session.id)}.json',
      ).writeAsString(jsonEncode(session.toJson()));
    }
    for (final snapshot in snapshots) {
      await File(
        '${_dir(paths[1]).path}${Platform.pathSeparator}${_safe(snapshot.id)}.json',
      ).writeAsString(jsonEncode(snapshot.toJson()));
    }
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}journal.json',
    ).writeAsString(jsonEncode(journal.map((e) => e.toJson()).toList()));
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}timeline.json',
    ).writeAsString(jsonEncode(timeline.map((e) => e.toJson()).toList()));
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}recovery.json',
    ).writeAsString(jsonEncode(recovery.map((e) => e.toJson()).toList()));
    await File(
      '${_dir(paths[6]).path}${Platform.pathSeparator}milestones.json',
    ).writeAsString(jsonEncode(milestones.map((e) => e.toJson()).toList()));
  }
}

class ReverseSessionRepositoryFactory {
  const ReverseSessionRepositoryFactory();
  ReverseSessionRepository create(Directory project) =>
      ReverseSessionRepository(project);
}
