enum HybridHistoryAction { build, compare, validate, explain }

class HybridHistoryEntry {
  const HybridHistoryEntry(
    this.action,
    this.planId,
    this.timestamp,
    this.metadata,
  );
  final HybridHistoryAction action;
  final String planId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

class HybridSurfaceHistory {
  final List<HybridHistoryEntry> _entries = [];
  List<HybridHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(
    HybridHistoryAction action,
    String planId, {
    Map<String, dynamic> metadata = const {},
  }) => _entries.add(
    HybridHistoryEntry(action, planId, DateTime.now(), metadata),
  );
}
