import 'dart:convert';
import '../../utils/id_generator.dart';

enum ReverseSessionStatus { created, open, paused, closed, archived, deleted }

class SessionContext {
  SessionContext({required this.projectId, Map<String, dynamic>? state})
    : state = _copy(state ?? const {});
  final String projectId;
  Map<String, dynamic> state;
  static const fields = [
    'workflow',
    'workspace',
    'layout',
    'ribbon',
    'docking',
    'viewport',
    'camera',
    'selection',
    'activeDatum',
    'activeSketch',
    'activeFeature',
    'alignment',
    'validation',
    'heatMap',
    'engineeringScore',
    'checklist',
    'timeline',
    'advisor',
    'analytics',
    'undo',
    'redo',
  ];
  static Map<String, dynamic> _copy(Map<String, dynamic> source) =>
      (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
  SessionContext copy() => SessionContext(projectId: projectId, state: state);
  Map<String, dynamic> toJson() => {'projectId': projectId, 'state': state};
}

class ReverseSession {
  ReverseSession({
    required this.name,
    required this.user,
    required this.context,
    String? id,
  }) : id = id ?? 'session:${IdGenerator.generate()}',
       createdAt = DateTime.now().toUtc(),
       updatedAt = DateTime.now().toUtc();
  final String id;
  String name, user;
  SessionContext context;
  ReverseSessionStatus status = ReverseSessionStatus.created;
  final DateTime createdAt;
  DateTime updatedAt;
  String? currentMilestone, currentSnapshot;
  double progress = 0;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'user': user,
    'status': status.name,
    'context': context.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'currentMilestone': currentMilestone,
    'currentSnapshot': currentSnapshot,
    'progress': progress,
  };
}

class SessionSnapshot {
  SessionSnapshot({
    required this.sessionId,
    required SessionContext context,
    required this.status,
    required this.progress,
    String? id,
  }) : id = id ?? 'session-snapshot:${IdGenerator.generate()}',
       context = context.copy(),
       createdAt = DateTime.now().toUtc();
  final String id, sessionId;
  final SessionContext context;
  final ReverseSessionStatus status;
  final double progress;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'context': context.toJson(),
    'status': status.name,
    'progress': progress,
    'createdAt': createdAt.toIso8601String(),
  };
}

class SessionJournalEntry {
  SessionJournalEntry({
    required this.sessionId,
    required this.activity,
    required this.user,
    required this.result,
    this.comment,
    this.elapsed = Duration.zero,
    String? id,
  }) : id = id ?? 'session-journal:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, sessionId, activity, user, result;
  final String? comment;
  final Duration elapsed;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'activity': activity,
    'user': user,
    'result': result,
    'comment': comment,
    'elapsedMicros': elapsed.inMicroseconds,
    'timestamp': timestamp.toIso8601String(),
  };
}

class SessionMilestone {
  SessionMilestone({required this.sessionId, required this.name, String? id})
    : id = id ?? 'session-milestone:${IdGenerator.generate()}',
      reachedAt = DateTime.now().toUtc();
  final String id, sessionId, name;
  final DateTime reachedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'name': name,
    'reachedAt': reachedAt.toIso8601String(),
  };
}

class RecoveryState {
  RecoveryState({
    required this.sessionId,
    required SessionContext context,
    required this.diagnostics,
    String? id,
  }) : id = id ?? 'session-recovery:${IdGenerator.generate()}',
       context = context.copy(),
       createdAt = DateTime.now().toUtc();
  final String id, sessionId, diagnostics;
  final SessionContext context;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'context': context.toJson(),
    'diagnostics': diagnostics,
    'createdAt': createdAt.toIso8601String(),
  };
}
