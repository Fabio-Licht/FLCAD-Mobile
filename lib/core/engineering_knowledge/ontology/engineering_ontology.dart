import '../models/knowledge_models.dart';

class OntologyEdge {
  const OntologyEdge(this.parent, this.child, this.relation);
  final String parent, child, relation;
}

class EngineeringOntology {
  EngineeringOntology({
    Iterable<KnowledgeConcept> concepts = const [],
    Iterable<OntologyEdge> edges = const [],
  }) {
    for (final c in concepts) {
      add(c);
    }
    for (final e in edges) {
      relate(e);
    }
  }
  final Map<String, KnowledgeConcept> _concepts = {};
  final List<OntologyEdge> _edges = [];
  Iterable<KnowledgeConcept> get concepts => _concepts.values;
  List<OntologyEdge> get edges => List.unmodifiable(_edges);
  void add(KnowledgeConcept concept) => _concepts[concept.id] = concept;
  KnowledgeConcept? find(String id) => _concepts[id];
  void relate(OntologyEdge edge) {
    if (!_concepts.containsKey(edge.parent) ||
        !_concepts.containsKey(edge.child)) {
      throw StateError('Ontology concepts must exist');
    }
    _edges.add(edge);
  }

  Set<String> ancestors(String id) {
    final result = <String>{}, queue = [id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final edge in _edges.where((e) => e.child == current)) {
        if (result.add(edge.parent)) queue.add(edge.parent);
      }
    }
    return result;
  }

  bool isA(String child, String parent) =>
      child == parent || ancestors(child).contains(parent);
}

class CoreEngineeringOntology {
  static const provenance = KnowledgeProvenance(
    'FLCAD Engineering DNA',
    '0.7.0',
    verified: true,
  );
  static EngineeringOntology create() {
    KnowledgeConcept c(String id, String name, String kind) => KnowledgeConcept(
      id: id,
      name: name,
      kind: kind,
      description: 'Core engineering ontology concept: $name',
      attributes: const {},
      provenance: provenance,
    );
    final concepts = [
      c('part', 'Part', 'entity'),
      c('feature', 'Feature', 'entity'),
      c('surface', 'Surface', 'geometry'),
      c('reference', 'Reference', 'geometry'),
      c('function', 'Function', 'semantics'),
      c('process', 'Process', 'manufacturing'),
      c('inspection', 'Inspection', 'quality'),
      c('manufacturing', 'Manufacturing', 'discipline'),
      c('hole', 'Hole', 'feature'),
      c('housing', 'Housing', 'feature'),
      c('bearingSeat', 'Bearing seat', 'feature'),
      c('flange', 'Flange', 'feature'),
    ];
    final o = EngineeringOntology(concepts: concepts);
    for (final edge in [
      const OntologyEdge('part', 'feature', 'contains'),
      const OntologyEdge('feature', 'surface', 'definedBy'),
      const OntologyEdge('surface', 'reference', 'measuredFrom'),
      const OntologyEdge('feature', 'function', 'performs'),
      const OntologyEdge('feature', 'process', 'createdBy'),
      const OntologyEdge('feature', 'inspection', 'verifiedBy'),
      const OntologyEdge('manufacturing', 'process', 'contains'),
      const OntologyEdge('feature', 'hole', 'isA'),
      const OntologyEdge('feature', 'housing', 'isA'),
      const OntologyEdge('housing', 'bearingSeat', 'contains'),
      const OntologyEdge('feature', 'flange', 'isA'),
    ]) {
      o.relate(edge);
    }
    return o;
  }
}
