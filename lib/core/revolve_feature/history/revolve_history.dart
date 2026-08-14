import '../../utils/id_generator.dart';

enum RevolveHistoryAction {
  create,
  edit,
  axisUpdate,
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

class RevolveHistoryEntry {
  RevolveHistoryEntry(this.action, this.target)
    : id = 'revolve-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final RevolveHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.name,
    'target': target,
    'timestamp': timestamp.toIso8601String(),
  };
}

class RevolveHistory {
  final List<RevolveHistoryEntry> _entries = [];
  List<RevolveHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(RevolveHistoryAction a, String t) =>
      _entries.add(RevolveHistoryEntry(a, t));
}
