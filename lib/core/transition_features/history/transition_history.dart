import '../../utils/id_generator.dart';

enum TransitionHistoryAction {
  create,
  edit,
  preview,
  confirm,
  rebuild,
  rollback,
  suppress,
  unsuppress,
  undo,
  redo,
  failure,
}

class TransitionHistoryEntry {
  TransitionHistoryEntry(this.action, this.target)
    : id = 'transition-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final TransitionHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
  };
}

class TransitionHistory {
  final List<TransitionHistoryEntry> _entries = [];
  List<TransitionHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(TransitionHistoryAction action, String target) =>
      _entries.add(TransitionHistoryEntry(action, target));
}
