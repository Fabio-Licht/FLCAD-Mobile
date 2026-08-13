import '../knowledge/knowledge_graph.dart';
import '../models/knowledge_models.dart';

class CoreEngineeringRelationships {
  static const p = KnowledgeProvenance(
    'FLCAD Relationship Library',
    '0.7.0',
    verified: true,
  );
  static EngineeringKnowledgeGraph create(Iterable<KnowledgeConcept> concepts) {
    final graph = EngineeringKnowledgeGraph();
    for (final c in concepts) {
      graph.addConcept(c);
    }
    void link(
      String id,
      String a,
      String relation,
      String b,
      double confidence,
    ) {
      if (graph.concepts.containsKey(a) && graph.concepts.containsKey(b)) {
        graph.addRelation(
          KnowledgeRelation(
            id: id,
            subject: a,
            predicate: relation,
            object: b,
            confidence: confidence,
            provenance: p,
          ),
        );
      }
    }

    link(
      'rel.bearing.housing',
      'bearingSeat',
      'requiresContext',
      'housing',
      .98,
    );
    link('rel.housing.axis', 'housing', 'requires', 'reference', .95);
    link('rel.seat.inspection', 'bearingSeat', 'verifiedBy', 'inspection', .95);
    link('rel.flange.holes', 'flange', 'contains', 'hole', .9);
    return graph;
  }
}
