import '../../utils/id_generator.dart';

enum AlignmentHistoryAction {
  create,
  update,
  preview,
  apply,
  cancel,
  commit,
  rollback,
  replay,
  delete,
  undo,
  redo,
  failure,
}

class AlignmentHistoryEntry {
  AlignmentHistoryEntry(this.action, this.target, {this.matrix = const []})
    : id = 'alignment-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final AlignmentHistoryAction action;
  final DateTime timestamp;
  final List<double> matrix;
  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target,
    'action': action.name,
    'matrix': matrix,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AlignmentHistory {
  final List<AlignmentHistoryEntry> _entries = [];
  List<AlignmentHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(
    AlignmentHistoryAction action,
    String target, {
    List<double> matrix = const [],
  }) => _entries.add(AlignmentHistoryEntry(action, target, matrix: matrix));
}
