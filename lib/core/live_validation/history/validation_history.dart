import '../../utils/id_generator.dart';
import '../models/validation_models.dart';

enum ValidationHistoryAction {
  start,
  pause,
  resume,
  stop,
  update,
  snapshot,
  baseline,
  rollback,
  replay,
}

class ValidationSnapshot {
  ValidationSnapshot({
    required this.sessionId,
    required this.metrics,
    required this.samples,
    String? id,
  }) : id = id ?? 'validation-snapshot:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, sessionId;
  final DateTime timestamp;
  final ValidationMetrics metrics;
  final List<DeviationSample> samples;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'metrics': metrics.toJson(),
    'samples': samples.map((e) => e.toJson()).toList(),
  };
}

class ValidationHistoryEntry {
  ValidationHistoryEntry(this.action, this.sessionId, {this.snapshotId})
    : id = 'validation-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, sessionId;
  final String? snapshotId;
  final ValidationHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'snapshotId': snapshotId,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ValidationHistory {
  final List<ValidationHistoryEntry> entries = [];
  final Map<String, ValidationSnapshot> snapshots = {}, baselines = {};
  void record(
    ValidationHistoryAction action,
    String sessionId, {
    String? snapshotId,
  }) => entries.add(
    ValidationHistoryEntry(action, sessionId, snapshotId: snapshotId),
  );
  ValidationSnapshot snapshot(LiveValidationSession session) {
    final metrics =
        session.metrics ?? (throw StateError('Validation has no metrics'));
    final snapshot = ValidationSnapshot(
      sessionId: session.id,
      metrics: metrics,
      samples: session.samples.values.toList(),
    );
    snapshots[snapshot.id] = snapshot;
    record(
      ValidationHistoryAction.snapshot,
      session.id,
      snapshotId: snapshot.id,
    );
    return snapshot;
  }

  void baseline(String sessionId, String snapshotId) {
    baselines[sessionId] =
        snapshots[snapshotId] ??
        (throw StateError('Unknown snapshot: $snapshotId'));
    record(ValidationHistoryAction.baseline, sessionId, snapshotId: snapshotId);
  }
}
