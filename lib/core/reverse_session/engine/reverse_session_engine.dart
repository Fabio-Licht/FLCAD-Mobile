import '../advisor/session_advisor.dart';
import '../analytics/session_analytics.dart';
import '../history/session_history.dart';
import '../journal/reverse_journal.dart';
import '../models/session_models.dart';
import '../recovery/recovery_engine.dart';
import '../repository/reverse_session_repository.dart';
import '../snapshot/session_snapshot_manager.dart';
import '../timeline/session_timeline.dart';
import '../validation/session_validation.dart';

class ReverseSessionEngine {
  ReverseSessionEngine({required this.repository});
  final ReverseSessionRepository repository;
  final Map<String, ReverseSession> sessions = {};
  final ReverseJournal journal = ReverseJournal();
  final SessionHistory history = SessionHistory();
  final SessionTimeline timeline = SessionTimeline();
  final SessionSnapshotManager snapshotManager = SessionSnapshotManager();
  final RecoveryEngine recovery = RecoveryEngine();
  final SessionAnalytics analytics = SessionAnalytics();
  final SessionAdvisor advisor = const SessionAdvisor();
  final SessionValidation validation = const SessionValidation();
  final List<SessionMilestone> milestones = [];
  String? activeId;
  ReverseSession get active =>
      sessions[activeId] ?? (throw StateError('No active reverse session'));

  ReverseSession create({
    required String name,
    required String user,
    required SessionContext context,
  }) {
    final session = ReverseSession(name: name, user: user, context: context);
    final errors = validation.validate(session);
    if (errors.isNotEmpty) {
      throw StateError(errors.join('; '));
    }
    sessions[session.id] = session;
    _event(session, 'Session created', 'created');
    milestone(session.id, 'Project created');
    return session;
  }

  void open(String id) {
    final session = _session(id);
    session.status = ReverseSessionStatus.open;
    activeId = id;
    _touch(session, 'Session opened');
  }

  void close(String id) {
    final session = _session(id);
    session.status = ReverseSessionStatus.closed;
    if (activeId == id) activeId = null;
    _touch(session, 'Session closed');
  }

  void pause(String id) {
    final session = _session(id);
    session.status = ReverseSessionStatus.paused;
    _touch(session, 'Session paused');
  }

  void resume(String id) {
    final session = _session(id);
    session.status = ReverseSessionStatus.open;
    activeId = id;
    _touch(session, 'Session resumed');
  }

  void archive(String id) {
    final session = _session(id);
    session.status = ReverseSessionStatus.archived;
    _touch(session, 'Session archived');
  }

  void delete(String id) {
    final session = _session(id);
    session.status = ReverseSessionStatus.deleted;
    if (activeId == id) activeId = null;
    _touch(session, 'Session deleted');
  }

  ReverseSession duplicate(String id) {
    final source = _session(id);
    final copy = create(
      name: '${source.name} Copy',
      user: source.user,
      context: source.context.copy(),
    );
    copy.progress = source.progress;
    return copy;
  }

  ReverseSession merge(String targetId, String sourceId) {
    final target = _session(targetId), source = _session(sourceId);
    target.context.state = {
      ...target.context.state,
      ...SessionContext(
        projectId: source.context.projectId,
        state: source.context.state,
      ).state,
    };
    target.progress = target.progress > source.progress
        ? target.progress
        : source.progress;
    _touch(target, 'Session merged');
    return target;
  }

  SessionSnapshot snapshot(String id) {
    final session = _session(id);
    final result = snapshotManager.capture(session);
    analytics.snapshots++;
    _event(session, 'Snapshot', result.id);
    return result;
  }

  void restore(String id, String snapshotId) {
    final session = _session(id),
        snap =
            snapshotManager.snapshots[snapshotId] ??
            (throw StateError('Unknown snapshot: $snapshotId'));
    if (snap.sessionId != id) {
      throw StateError('Snapshot does not belong to session: $id');
    }
    session.context = snap.context.copy();
    session.status = snap.status;
    session.progress = snap.progress;
    session.currentSnapshot = snap.id;
    _touch(session, 'Snapshot restored');
  }

  RecoveryState crashRecovery(String id) {
    final session = _session(id);
    final state = recovery.capture(session);
    _event(session, 'Crash recovery captured', state.id);
    return state;
  }

  void restoreRecovery(String id) {
    final session = _session(id),
        state =
            recovery.states[id] ?? (throw StateError('No recovery state: $id'));
    final errors = recovery.validate(state);
    if (errors.isNotEmpty) throw StateError(errors.join('; '));
    session.context = state.context.copy();
    _touch(session, 'Recovery restored');
  }

  SessionMilestone milestone(String id, String name) {
    final session = _session(id);
    final value = SessionMilestone(sessionId: id, name: name);
    milestones.add(value);
    session.currentMilestone = value.id;
    _event(session, 'Milestone', name);
    return value;
  }

  List<SessionJournalEntry> replay(String id) =>
      List.unmodifiable(journal.forSession(id));
  void record(
    String id,
    String activity, {
    String result = 'completed',
    String? comment,
    Duration elapsed = Duration.zero,
  }) {
    final session = _session(id);
    final entry = SessionJournalEntry(
      sessionId: id,
      activity: activity,
      user: session.user,
      result: result,
      comment: comment,
      elapsed: elapsed,
    );
    journal.record(entry);
    history.add(entry);
    timeline.add(entry);
    analytics.update(
      elapsed: elapsed,
      step: activity,
      workspace: session.context.state['workspace']?.toString(),
    );
  }

  List<String> recommendations(String id) =>
      advisor.recommendations(_session(id));
  Future<void> persist() => repository.save(
    sessions: sessions.values,
    snapshots: snapshotManager.snapshots.values,
    journal: journal.entries,
    timeline: timeline.entries,
    recovery: recovery.states.values,
    milestones: milestones,
    analytics: analytics,
  );
  ReverseSession _session(String id) =>
      sessions[id] ?? (throw StateError('Unknown reverse session: $id'));
  void _touch(ReverseSession session, String activity) {
    session.updatedAt = DateTime.now().toUtc();
    _event(session, activity, 'completed');
  }

  void _event(ReverseSession session, String activity, String result) =>
      record(session.id, activity, result: result);
}
