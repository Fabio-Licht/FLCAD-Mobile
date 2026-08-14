import '../models/session_models.dart';

class SessionTimeline {
  final List<SessionJournalEntry> entries = [];
  void add(SessionJournalEntry entry) => entries.add(entry);
}
