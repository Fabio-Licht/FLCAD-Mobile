import '../models/session_models.dart';

class SessionSnapshotManager {
  final Map<String, SessionSnapshot> snapshots = {};
  SessionSnapshot capture(ReverseSession session) {
    final snapshot = SessionSnapshot(
      sessionId: session.id,
      context: session.context,
      status: session.status,
      progress: session.progress,
    );
    snapshots[snapshot.id] = snapshot;
    session.currentSnapshot = snapshot.id;
    return snapshot;
  }
}
