import '../models/knowledge_models.dart';

class EngineeringKnowledgeGraph {
  final Map<String, KnowledgeConcept> concepts = {};
  final Map<String, KnowledgeRelation> relations = {};
  void addConcept(KnowledgeConcept concept) => concepts[concept.id] = concept;
  void addRelation(KnowledgeRelation relation) {
    if (!concepts.containsKey(relation.subject) ||
        !concepts.containsKey(relation.object)) {
      throw StateError('Relation endpoints must exist');
    }
    relations[relation.id] = relation;
  }

  List<KnowledgeRelation> outgoing(String id) =>
      relations.values.where((r) => r.subject == id).toList();
  List<KnowledgeRelation> incoming(String id) =>
      relations.values.where((r) => r.object == id).toList();
  List<String> path(String from, String to) {
    final queue = <List<String>>[
          [from],
        ],
        visited = <String>{from};
    while (queue.isNotEmpty) {
      final path = queue.removeAt(0), last = path.last;
      if (last == to) return path;
      for (final relation in outgoing(last)) {
        if (visited.add(relation.object)) queue.add([...path, relation.object]);
      }
    }
    return const [];
  }
}
