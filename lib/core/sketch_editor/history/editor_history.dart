import '../../utils/id_generator.dart';

enum EditorHistoryAction {
  create,
  edit,
  select,
  snap,
  preview,
  commit,
  cancel,
  undo,
  redo,
  rollback,
}

class EditorHistoryEntry {
  EditorHistoryEntry(this.action, this.target)
    : id = 'editor-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id;
  final EditorHistoryAction action;
  final String target;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.name,
    'target': target,
    'timestamp': timestamp.toIso8601String(),
  };
}

class EditorHistory {
  final List<EditorHistoryEntry> _entries = [];
  List<EditorHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(EditorHistoryAction action, String target) =>
      _entries.add(EditorHistoryEntry(action, target));
  void truncate(int length) => _entries.removeRange(length, _entries.length);
}
