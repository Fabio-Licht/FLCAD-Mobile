import '../../ai_engineering/models/ai_engineering_models.dart';

enum EngineeringFeatureType {
  simpleHole,
  throughHole,
  blindHole,
  steppedHole,
  countersunkHole,
  threadedHole,
  cylindricalBoss,
  prismaticBoss,
  rectangularPocket,
  circularPocket,
  organicPocket,
  flange,
  bearingSeat,
  housing,
  shaft,
  rib,
  slot,
  keyway,
  draftRegion,
  revolution,
  extrusion,
  loftCandidate,
  blendRegion,
  fillet,
  chamfer,
  moldPartingCandidate,
  stampingRegion,
  electrodeCandidate,
  machiningFeature,
  datumFeature,
}

enum FeatureFunction {
  functional,
  structural,
  manufacturing,
  reference,
  assembly,
  inspection,
  cam,
}

enum FeatureDecisionType { accepted, rejected }

enum FeatureRelationshipType {
  coaxiality,
  parallelism,
  perpendicularity,
  alignment,
  dependency,
  sequence,
}

List<T> _list<T>(Iterable<T> value) => List<T>.unmodifiable(value);

class FeatureEvidence {
  FeatureEvidence({
    required this.id,
    required this.source,
    required this.description,
    required Iterable<String> primitiveIds,
    required this.score,
  }) : primitiveIds = _list(primitiveIds) {
    if (this.primitiveIds.isEmpty) {
      throw ArgumentError.value(
        primitiveIds,
        'primitiveIds',
        'must not be empty',
      );
    }
  }
  final String id, source, description;
  final List<String> primitiveIds;
  final double score;
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'description': description,
    'primitiveIds': primitiveIds,
    'score': score,
  };
}

class FeatureGraphNode {
  const FeatureGraphNode({
    required this.id,
    required this.kind,
    required this.referenceId,
  });
  final String id, kind, referenceId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'referenceId': referenceId,
  };
}

class FeatureGraphEdge {
  const FeatureGraphEdge({
    required this.from,
    required this.to,
    required this.relationship,
    required this.score,
  });
  final String from, to;
  final FeatureRelationshipType relationship;
  final double score;
  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'relationship': relationship.name,
    'score': score,
  };
}

class FeatureGraph {
  FeatureGraph({
    required this.id,
    required Iterable<FeatureGraphNode> nodes,
    required Iterable<FeatureGraphEdge> edges,
  }) : nodes = _list(nodes),
       edges = _list(edges) {
    final ids = this.nodes.map((e) => e.id).toSet();
    if (ids.length != this.nodes.length) {
      throw ArgumentError('Feature graph node IDs must be unique');
    }
    if (this.edges.any((e) => !ids.contains(e.from) || !ids.contains(e.to))) {
      throw ArgumentError('Feature graph edge references an unknown node');
    }
    if (_hasCycle(ids, this.edges)) {
      throw ArgumentError('Feature graph must be acyclic');
    }
  }
  final String id;
  final List<FeatureGraphNode> nodes;
  final List<FeatureGraphEdge> edges;
  static bool _hasCycle(Set<String> ids, List<FeatureGraphEdge> edges) {
    final outgoing = {for (final id in ids) id: <String>[]};
    for (final edge in edges) {
      outgoing[edge.from]!.add(edge.to);
    }
    final visiting = <String>{}, visited = <String>{};
    bool visit(String id) {
      if (visiting.contains(id)) {
        return true;
      }
      if (visited.contains(id)) {
        return false;
      }
      visiting.add(id);
      for (final next in outgoing[id]!) {
        if (visit(next)) {
          return true;
        }
      }
      visiting.remove(id);
      visited.add(id);
      return false;
    }

    return ids.any(visit);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nodes': nodes.map((e) => e.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
    'acyclic': true,
  };
}

class FeatureConfidenceNode {
  FeatureConfidenceNode({
    required this.id,
    required this.label,
    required this.confidence,
    required Iterable<FeatureConfidenceNode> children,
    required Iterable<String> evidenceIds,
  }) : children = _list(children),
       evidenceIds = _list(evidenceIds);
  final String id, label;
  final double confidence;
  final List<FeatureConfidenceNode> children;
  final List<String> evidenceIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'confidence': confidence,
    'evidenceIds': evidenceIds,
    'children': children.map((e) => e.toJson()).toList(),
  };
}

class FeatureScores {
  const FeatureScores({
    required this.geometricScore,
    required this.topologyScore,
    required this.functionalScore,
    required this.manufacturingScore,
    required this.symmetryScore,
    required this.contextScore,
    required this.historyScore,
    required this.overallConfidence,
  });
  final double geometricScore,
      topologyScore,
      functionalScore,
      manufacturingScore,
      symmetryScore,
      contextScore,
      historyScore,
      overallConfidence;
  Map<String, dynamic> toJson() => {
    'geometricScore': geometricScore,
    'topologyScore': topologyScore,
    'functionalScore': functionalScore,
    'manufacturingScore': manufacturingScore,
    'symmetryScore': symmetryScore,
    'contextScore': contextScore,
    'historyScore': historyScore,
    'overallConfidence': overallConfidence,
  };
}

class ReconstructionStrategy {
  ReconstructionStrategy({
    required this.featureType,
    required Iterable<String> steps,
    required this.justification,
  }) : steps = _list(steps);
  final EngineeringFeatureType featureType;
  final List<String> steps;
  final String justification;
  Map<String, dynamic> toJson() => {
    'featureType': featureType.name,
    'steps': steps,
    'justification': justification,
    'consultative': true,
    'executed': false,
  };
}

class CanonicalFeatureSuggestion {
  const CanonicalFeatureSuggestion({
    required this.measuredFeature,
    required this.canonicalFeature,
    required this.justification,
    required this.deviation,
    required this.confidence,
  });
  final String measuredFeature, canonicalFeature, justification;
  final double deviation, confidence;
  Map<String, dynamic> toJson() => {
    'measuredFeature': measuredFeature,
    'canonicalFeature': canonicalFeature,
    'justification': justification,
    'deviation': deviation,
    'confidence': confidence,
    'applied': false,
  };
}

class EngineeringFeatureHypothesis {
  EngineeringFeatureHypothesis({
    required this.id,
    required this.type,
    required this.function,
    required this.graph,
    required this.confidenceTree,
    required this.scores,
    required Iterable<FeatureEvidence> evidence,
    required this.justification,
    required Iterable<String> discardedHypotheses,
    required this.strategy,
    required this.canonicalSuggestion,
  }) : evidence = _list(evidence),
       discardedHypotheses = _list(discardedHypotheses) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id, justification;
  final EngineeringFeatureType type;
  final FeatureFunction function;
  final FeatureGraph graph;
  final FeatureConfidenceNode confidenceTree;
  final FeatureScores scores;
  final List<FeatureEvidence> evidence;
  final List<String> discardedHypotheses;
  final ReconstructionStrategy strategy;
  final CanonicalFeatureSuggestion canonicalSuggestion;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'function': function.name,
    'graph': graph.toJson(),
    'confidenceTree': confidenceTree.toJson(),
    'scores': scores.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'justification': justification,
    'discardedHypotheses': discardedHypotheses,
    'strategy': strategy.toJson(),
    'canonicalSuggestion': canonicalSuggestion.toJson(),
    'commandsExecuted': false,
    'entitiesCreated': false,
    'geometryModified': false,
  };
}

class EngineeringDna {
  EngineeringDna({
    required Iterable<String> predominantFeatures,
    required Iterable<String> geometricRelationships,
    required Iterable<String> topologicalRelationships,
    required Iterable<String> symmetries,
    required this.probableManufacturingStrategy,
    required Iterable<String> probableReconstructionStrategy,
    required this.geometricComplexity,
    required this.functionalComplexity,
  }) : predominantFeatures = _list(predominantFeatures),
       geometricRelationships = _list(geometricRelationships),
       topologicalRelationships = _list(topologicalRelationships),
       symmetries = _list(symmetries),
       probableReconstructionStrategy = _list(probableReconstructionStrategy);
  final List<String> predominantFeatures,
      geometricRelationships,
      topologicalRelationships,
      symmetries,
      probableReconstructionStrategy;
  final String probableManufacturingStrategy;
  final double geometricComplexity, functionalComplexity;
  Map<String, dynamic> toJson() => {
    'predominantFeatures': predominantFeatures,
    'geometricRelationships': geometricRelationships,
    'topologicalRelationships': topologicalRelationships,
    'symmetries': symmetries,
    'probableManufacturingStrategy': probableManufacturingStrategy,
    'probableReconstructionStrategy': probableReconstructionStrategy,
    'geometricComplexity': geometricComplexity,
    'functionalComplexity': functionalComplexity,
  };
}

typedef EngineeringDNA = EngineeringDna;
typedef FeatureConfidenceTree = FeatureConfidenceNode;

class FeatureDecision {
  const FeatureDecision({
    required this.hypothesisId,
    required this.type,
    required this.reason,
    required this.sequence,
  });
  final String hypothesisId, reason;
  final FeatureDecisionType type;
  final int sequence;
  Map<String, dynamic> toJson() => {
    'hypothesisId': hypothesisId,
    'type': type.name,
    'reason': reason,
    'sequence': sequence,
  };
}

class EngineeringFeatureSession {
  EngineeringFeatureSession({
    required this.id,
    required this.context,
    required Iterable<EngineeringFeatureHypothesis> hypotheses,
    required Iterable<FeatureDecision> decisions,
    required this.dna,
  }) : hypotheses = _list(hypotheses),
       decisions = _list(decisions);
  final String id;
  final EngineeringContextSnapshot context;
  final List<EngineeringFeatureHypothesis> hypotheses;
  final List<FeatureDecision> decisions;
  final EngineeringDna dna;
  EngineeringFeatureSession copyWith({Iterable<FeatureDecision>? decisions}) =>
      EngineeringFeatureSession(
        id: id,
        context: context,
        hypotheses: hypotheses,
        decisions: decisions ?? this.decisions,
        dna: dna,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context.toJson(),
    'hypotheses': hypotheses.map((e) => e.toJson()).toList(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'engineeringDna': dna.toJson(),
    'commandsExecuted': false,
    'entitiesCreated': false,
    'geometryModified': false,
  };
}
