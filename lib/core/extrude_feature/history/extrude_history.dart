import '../../utils/id_generator.dart';

enum ExtrudeHistoryAction {
  create,
  edit,
  preview,
  confirm,
  delete,
  suppress,
  unsuppress,
  rebuild,
  rollback,
  undo,
  redo,
  failure,
}

class ExtrudeHistoryEntry {
  ExtrudeHistoryEntry(this.action, this.target)
    : id = 'extrude-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final ExtrudeHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.name,
    'target': target,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ExtrudeHistory {
  final List<ExtrudeHistoryEntry> _entries = [];
  List<ExtrudeHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(ExtrudeHistoryAction a, String t) =>
      _entries.add(ExtrudeHistoryEntry(a, t));
}
