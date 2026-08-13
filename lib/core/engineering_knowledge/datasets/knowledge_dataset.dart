import 'dart:convert';
import '../models/knowledge_models.dart';

class KnowledgeDataset {
  const KnowledgeDataset(this.id, this.version, this.concepts);
  final String id, version;
  final List<KnowledgeConcept> concepts;
}

class KnowledgeDatasetCodec {
  const KnowledgeDatasetCodec();
  KnowledgeDataset decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>,
        id = json['id'] as String,
        version = json['version'] as String,
        items = (json['concepts'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
    final concepts = items
        .map(
          (j) => KnowledgeConcept(
            id: j['id'] as String,
            name: j['name'] as String,
            kind: j['kind'] as String,
            description: j['description'] as String? ?? '',
            attributes: Map<String, dynamic>.from(
              j['attributes'] as Map? ?? const {},
            ),
            provenance: KnowledgeProvenance(
              'dataset:$id',
              version,
              reference: j['reference'] as String?,
            ),
            tags: (j['tags'] as List? ?? const []).cast<String>(),
          ),
        )
        .toList();
    return KnowledgeDataset(id, version, concepts);
  }

  String encode(KnowledgeDataset data) => jsonEncode({
    'id': data.id,
    'version': data.version,
    'concepts': data.concepts.map((c) => c.toJson()).toList(),
  });
}
