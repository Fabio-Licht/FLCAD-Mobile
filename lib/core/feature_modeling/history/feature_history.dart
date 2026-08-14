import '../../utils/id_generator.dart';

enum FeatureHistoryAction {
  create,
  delete,
  edit,
  suppress,
  unsuppress,
  freeze,
  unfreeze,
  rebuild,
  rollback,
  undo,
  redo,
  failure,
}

class FeatureHistoryEntry {
  FeatureHistoryEntry(this.action, this.target)
    : id = 'feature-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final FeatureHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.name,
    'target': target,
    'timestamp': timestamp.toIso8601String(),
  };
}

class FeatureHistory {
  final List<FeatureHistoryEntry> _entries = [];
  List<FeatureHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(FeatureHistoryAction a, String t) =>
      _entries.add(FeatureHistoryEntry(a, t));
}
