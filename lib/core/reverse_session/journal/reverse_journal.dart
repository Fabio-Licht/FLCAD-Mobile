import '../models/session_models.dart';

class ReverseJournal {
  final List<SessionJournalEntry> entries = [];
  void record(SessionJournalEntry entry) => entries.add(entry);
  List<SessionJournalEntry> forSession(String id) =>
      entries.where((e) => e.sessionId == id).toList(growable: false);
}
