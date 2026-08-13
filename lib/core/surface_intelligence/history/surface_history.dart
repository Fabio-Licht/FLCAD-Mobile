enum SurfaceHistoryAction { plan, compare, validate, explain }

class SurfaceHistoryEntry {
  const SurfaceHistoryEntry(
    this.action,
    this.planId,
    this.timestamp,
    this.metadata,
  );
  final SurfaceHistoryAction action;
  final String planId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

class SurfaceIntelligenceHistory {
  final List<SurfaceHistoryEntry> _entries = [];
  List<SurfaceHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(
    SurfaceHistoryAction action,
    String planId, {
    Map<String, dynamic> metadata = const {},
  }) => _entries.add(
    SurfaceHistoryEntry(action, planId, DateTime.now(), metadata),
  );
}
