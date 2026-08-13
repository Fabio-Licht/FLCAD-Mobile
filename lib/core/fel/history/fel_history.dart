class FELHistoryEntry {
  const FELHistoryEntry({
    required this.source,
    required this.command,
    required this.timestamp,
    required this.description,
    this.undo,
  });
  final String source, command, description;
  final DateTime timestamp;
  final Future<void> Function()? undo;
}

class FELHistory {
  final List<FELHistoryEntry> _entries = [];
  var _cursor = 0;
  List<FELHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _entries.length;
  void record(FELHistoryEntry entry) {
    if (_cursor < _entries.length) {
      _entries.removeRange(_cursor, _entries.length);
    }
    _entries.add(entry);
    _cursor = _entries.length;
  }

  Future<void> undo() async {
    if (!canUndo) return;
    final entry = _entries[_cursor - 1];
    await entry.undo?.call();
    _cursor--;
  }

  FELHistoryEntry? redoEntry() => canRedo ? _entries[_cursor++] : null;
  String replaySource() => _entries
      .map((entry) => entry.source)
      .where((source) => source.trim().isNotEmpty)
      .join('\n');
  void clear() {
    _entries.clear();
    _cursor = 0;
  }
}
