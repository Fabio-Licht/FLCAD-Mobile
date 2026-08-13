import 'dart:convert';
import '../models/knowledge_models.dart';

class KnowledgeSerialization {
  const KnowledgeSerialization();
  String exportConcepts(Iterable<KnowledgeConcept> concepts) => jsonEncode({
    'schema': 'flcad.engineering-knowledge',
    'version': '0.7.0',
    'concepts': concepts.map((c) => c.toJson()).toList(),
  });
  String exportInferences(Iterable<KnowledgeInference> values) => jsonEncode({
    'schema': 'flcad.engineering-inferences',
    'version': 1,
    'inferences': values
        .map(
          (i) => {
            'conclusion': i.conclusion,
            'confidence': i.confidence,
            'explanation': i.explanation,
            'ruleIds': i.ruleIds,
            'evidence': i.evidence
                .map(
                  (e) => {
                    'id': e.id,
                    'description': e.description,
                    'value': e.value,
                    'source': e.source,
                    'reliability': e.reliability,
                  },
                )
                .toList(),
          },
        )
        .toList(),
  });
}
