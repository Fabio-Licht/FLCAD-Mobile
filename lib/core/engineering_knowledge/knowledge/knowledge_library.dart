import '../models/knowledge_models.dart';

class KnowledgeLibrary {
  KnowledgeLibrary([Iterable<KnowledgeConcept> entries = const []]) {
    for (final entry in entries) {
      register(entry);
    }
  }
  final Map<String, KnowledgeConcept> _entries = {};
  Iterable<KnowledgeConcept> get entries => _entries.values;
  void register(KnowledgeConcept entry) => _entries[entry.id] = entry;
  KnowledgeConcept? find(String id) => _entries[id];
  List<KnowledgeConcept> search(String query) {
    final q = query.toLowerCase();
    return _entries.values
        .where(
          (e) =>
              e.id.toLowerCase().contains(q) ||
              e.name.toLowerCase().contains(q) ||
              e.tags.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }

  void merge(KnowledgeLibrary other) {
    for (final entry in other.entries) {
      register(entry);
    }
  }
}
