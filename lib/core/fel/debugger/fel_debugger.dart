class FELDebugEntry {
  const FELDebugEntry({
    required this.line,
    required this.command,
    required this.duration,
    required this.result,
    this.error,
  });
  final int line;
  final String command, result;
  final Duration duration;
  final String? error;
}

class FELDebugger {
  final List<FELDebugEntry> _entries = [];
  List<FELDebugEntry> get entries => List.unmodifiable(_entries);
  void record(FELDebugEntry entry) => _entries.add(entry);
  void clear() => _entries.clear();
}
