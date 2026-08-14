import '../models/session_models.dart';

class SessionHistory {
  final List<SessionJournalEntry> entries = [];
  void add(SessionJournalEntry entry) => entries.add(entry);
}
