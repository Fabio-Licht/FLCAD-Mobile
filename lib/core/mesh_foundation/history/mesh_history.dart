class MeshHistoryEntry {
  MeshHistoryEntry(this.meshId, this.action)
    : timestamp = DateTime.now().toUtc();
  final String meshId, action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'meshId': meshId,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };
}

class MeshHistory {
  final List<MeshHistoryEntry> entries = [];
  void add(String id, String action) =>
      entries.add(MeshHistoryEntry(id, action));
}
