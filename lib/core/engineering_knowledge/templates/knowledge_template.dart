import '../models/knowledge_models.dart';

class KnowledgeTemplate {
  const KnowledgeTemplate(this.id, this.kind, this.requiredAttributes);
  final String id, kind;
  final List<String> requiredAttributes;
  KnowledgeConcept instantiate({
    required String conceptId,
    required String name,
    required Map<String, dynamic> attributes,
    required KnowledgeProvenance provenance,
  }) {
    final missing = requiredAttributes
        .where((key) => !attributes.containsKey(key))
        .toList();
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'Missing knowledge attributes: ${missing.join(', ')}',
      );
    }
    return KnowledgeConcept(
      id: conceptId,
      name: name,
      kind: kind,
      description: 'Created from template $id',
      attributes: Map.unmodifiable(attributes),
      provenance: provenance,
    );
  }
}
