import '../../utils/id_generator.dart';

enum ProfileHistoryAction {
  recognize,
  validate,
  merge,
  split,
  select,
  undo,
  redo,
  rollback,
}

class ProfileHistoryEntry {
  ProfileHistoryEntry(this.action, this.target)
    : id = 'profile-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, target;
  final ProfileHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.name,
    'target': target,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ProfileHistory {
  final List<ProfileHistoryEntry> _entries = [];
  List<ProfileHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(ProfileHistoryAction a, String t) =>
      _entries.add(ProfileHistoryEntry(a, t));
}
