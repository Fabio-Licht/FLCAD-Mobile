class ProjectHistory {
  const ProjectHistory({
    this.lastOpenedAt,
    this.lastCaptureAt,
    this.lastEditedAt,
    this.lastSyncedAt,
  });

  final DateTime? lastOpenedAt;
  final DateTime? lastCaptureAt;
  final DateTime? lastEditedAt;
  final DateTime? lastSyncedAt;

  DateTime? get lastModifiedAt => lastEditedAt ?? lastCaptureAt ?? lastOpenedAt;

  ProjectHistory copyWith({
    DateTime? lastOpenedAt,
    DateTime? lastCaptureAt,
    DateTime? lastEditedAt,
    DateTime? lastSyncedAt,
  }) => ProjectHistory(
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    lastCaptureAt: lastCaptureAt ?? this.lastCaptureAt,
    lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}
