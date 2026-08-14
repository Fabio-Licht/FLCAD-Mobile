import '../../utils/id_generator.dart';

enum ReferenceHistoryAction {
  create,
  edit,
  delete,
  rename,
  move,
  suppress,
  unsuppress,
  freeze,
  unfreeze,
  group,
  visibility,
  preview,
  confirm,
  rebuild,
  undo,
  redo,
  failure,
}

class ReferenceHistoryEntry {
  ReferenceHistoryEntry(this.action, this.target)
    : id = 'reference-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final ReferenceHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ReferenceHistory {
  final List<ReferenceHistoryEntry> _entries = [];
  List<ReferenceHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(ReferenceHistoryAction action, String target) =>
      _entries.add(ReferenceHistoryEntry(action, target));
}
