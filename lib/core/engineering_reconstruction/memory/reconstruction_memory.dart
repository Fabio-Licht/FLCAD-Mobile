class ReconstructionMemoryRecord {
  const ReconstructionMemoryRecord(
    this.projectId,
    this.strategyId,
    this.outcome,
    this.elapsed,
    this.interventions,
    this.timestamp,
  );
  final String projectId, strategyId, outcome;
  final Duration elapsed;
  final int interventions;
  final DateTime timestamp;
}

class ReconstructionMemory {
  final List<ReconstructionMemoryRecord> _records = [];
  void save(ReconstructionMemoryRecord record) => _records.add(record);
  List<ReconstructionMemoryRecord> forProject(String id) =>
      _records.where((e) => e.projectId == id).toList(growable: false);
  Map<String, double> strategySuccess() {
    final g = <String, List<ReconstructionMemoryRecord>>{};
    for (final r in _records) {
      g.putIfAbsent(r.strategyId, () => []).add(r);
    }
    return {
      for (final e in g.entries)
        e.key:
            e.value.where((r) => r.outcome == 'accepted').length /
            e.value.length,
    };
  }
}
