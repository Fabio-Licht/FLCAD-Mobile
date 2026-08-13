class EngineeringHistoryEntry<T> {
  const EngineeringHistoryEntry({
    required this.id,
    required this.projectId,
    required this.entityId,
    required this.domain,
    required this.action,
    required this.snapshot,
    required this.timestamp,
    required this.sequence,
    this.branchId = 'main',
  });
  final String id, projectId, entityId, domain, action, branchId;
  final T snapshot;
  final DateTime timestamp;
  final int sequence;
}

class EngineeringHistory {
  final List<EngineeringHistoryEntry<dynamic>> _entries = [];
  EngineeringHistoryEntry<T> record<T>({
    required String projectId,
    required String entityId,
    required String domain,
    required String action,
    required T snapshot,
    String branchId = 'main',
  }) {
    final entry = EngineeringHistoryEntry<T>(
      id: 'history:${DateTime.now().microsecondsSinceEpoch}',
      projectId: projectId,
      entityId: entityId,
      domain: domain,
      action: action,
      snapshot: snapshot,
      timestamp: DateTime.now(),
      sequence: _entries.length + 1,
      branchId: branchId,
    );
    _entries.add(entry);
    return entry;
  }

  List<EngineeringHistoryEntry<dynamic>> query({
    String? projectId,
    String? entityId,
    String? domain,
    String? branchId,
  }) => List.unmodifiable(
    _entries.where(
      (e) =>
          (projectId == null || e.projectId == projectId) &&
          (entityId == null || e.entityId == entityId) &&
          (domain == null || e.domain == domain) &&
          (branchId == null || e.branchId == branchId),
    ),
  );
  T replay<T>(String entityId, int sequence) =>
      _entries
              .firstWhere(
                (e) => e.entityId == entityId && e.sequence == sequence,
              )
              .snapshot
          as T;
}
