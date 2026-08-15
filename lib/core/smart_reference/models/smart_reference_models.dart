import '../../ai_engineering/models/ai_engineering_models.dart';

enum ReferenceCandidateType {
  basePlane,
  topPlane,
  functionalPlane,
  supportPlane,
  symmetryPlane,
  datumPlane,
  manufacturingPlane,
  mainAxis,
  secondaryAxis,
  revolutionAxis,
  functionalAxis,
  symmetryAxis,
  datumAxis,
  mainCenter,
  functionalCenter,
  suggestedOrigin,
  datumPoint,
  geometricCenter,
  centerOfMass,
  suggestedGlobalSystem,
  machiningSystem,
  inspectionSystem,
  localSystem,
  functionalSystem,
}

enum ReferenceCategory { plane, axis, point, coordinateSystem }

enum ReferenceDecisionType { accepted, rejected }

enum DatumLabel { a, b, c }

List<T> _list<T>(Iterable<T> value) => List<T>.unmodifiable(value);

ReferenceCategory categoryOf(ReferenceCandidateType type) => switch (type) {
  ReferenceCandidateType.basePlane ||
  ReferenceCandidateType.topPlane ||
  ReferenceCandidateType.functionalPlane ||
  ReferenceCandidateType.supportPlane ||
  ReferenceCandidateType.symmetryPlane ||
  ReferenceCandidateType.datumPlane ||
  ReferenceCandidateType.manufacturingPlane => ReferenceCategory.plane,
  ReferenceCandidateType.mainAxis ||
  ReferenceCandidateType.secondaryAxis ||
  ReferenceCandidateType.revolutionAxis ||
  ReferenceCandidateType.functionalAxis ||
  ReferenceCandidateType.symmetryAxis ||
  ReferenceCandidateType.datumAxis => ReferenceCategory.axis,
  ReferenceCandidateType.mainCenter ||
  ReferenceCandidateType.functionalCenter ||
  ReferenceCandidateType.suggestedOrigin ||
  ReferenceCandidateType.datumPoint ||
  ReferenceCandidateType.geometricCenter ||
  ReferenceCandidateType.centerOfMass => ReferenceCategory.point,
  _ => ReferenceCategory.coordinateSystem,
};

class ReferenceEvidence {
  ReferenceEvidence({
    required this.id,
    required this.source,
    required this.description,
    required Iterable<String> primitiveIds,
    required Iterable<String> featureIds,
    required this.score,
  }) : primitiveIds = _list(primitiveIds),
       featureIds = _list(featureIds) {
    if (this.primitiveIds.isEmpty && this.featureIds.isEmpty) {
      throw ArgumentError('Reference evidence requires a primitive or feature');
    }
  }
  final String id, source, description;
  final List<String> primitiveIds, featureIds;
  final double score;
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'description': description,
    'primitiveIds': primitiveIds,
    'featureIds': featureIds,
    'score': score,
  };
}

class ReferenceScores {
  const ReferenceScores({
    required this.geometricScore,
    required this.topologyScore,
    required this.manufacturingScore,
    required this.functionalScore,
    required this.symmetryScore,
    required this.featureScore,
    required this.contextScore,
    required this.historyScore,
    required this.overallConfidence,
  });
  final double geometricScore,
      topologyScore,
      manufacturingScore,
      functionalScore,
      symmetryScore,
      featureScore,
      contextScore,
      historyScore,
      overallConfidence;
  Map<String, dynamic> toJson() => {
    'geometricScore': geometricScore,
    'topologyScore': topologyScore,
    'manufacturingScore': manufacturingScore,
    'functionalScore': functionalScore,
    'symmetryScore': symmetryScore,
    'featureScore': featureScore,
    'contextScore': contextScore,
    'historyScore': historyScore,
    'overallConfidence': overallConfidence,
  };
}

class CanonicalReferenceSuggestion {
  const CanonicalReferenceSuggestion({
    required this.measuredReference,
    required this.canonicalReference,
    required this.angularErrorDegrees,
    required this.confidence,
    required this.justification,
    required this.reasons,
  });
  final String measuredReference, canonicalReference, justification;
  final double angularErrorDegrees, confidence;
  final List<String> reasons;
  Map<String, dynamic> toJson() => {
    'measuredReference': measuredReference,
    'canonicalReference': canonicalReference,
    'angularErrorDegrees': angularErrorDegrees,
    'confidence': confidence,
    'justification': justification,
    'reasons': reasons,
    'applied': false,
  };
}

class ReferenceCandidate {
  ReferenceCandidate({
    required this.id,
    required this.type,
    required this.scores,
    required Iterable<ReferenceEvidence> evidence,
    required this.justification,
    required Iterable<String> primitiveIds,
    required Iterable<String> featureIds,
    required Iterable<String> topologicalRelationships,
    required Iterable<String> discardedHypotheses,
    required this.canonical,
  }) : evidence = _list(evidence),
       primitiveIds = _list(primitiveIds),
       featureIds = _list(featureIds),
       topologicalRelationships = _list(topologicalRelationships),
       discardedHypotheses = _list(discardedHypotheses) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id, justification;
  final ReferenceCandidateType type;
  final ReferenceScores scores;
  final List<ReferenceEvidence> evidence;
  final List<String> primitiveIds,
      featureIds,
      topologicalRelationships,
      discardedHypotheses;
  final CanonicalReferenceSuggestion canonical;
  ReferenceCategory get category => categoryOf(type);
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'category': category.name,
    'scores': scores.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'justification': justification,
    'primitiveIds': primitiveIds,
    'featureIds': featureIds,
    'topologicalRelationships': topologicalRelationships,
    'discardedHypotheses': discardedHypotheses,
    'canonical': canonical.toJson(),
    'entityCreated': false,
    'geometryModified': false,
  };
}

class ReferenceDependency {
  const ReferenceDependency({
    required this.from,
    required this.to,
    required this.reason,
  });
  final String from, to, reason;
  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'reason': reason};
}

class ReferenceDependencyGraph {
  ReferenceDependencyGraph({
    required Iterable<String> nodes,
    required Iterable<ReferenceDependency> dependencies,
  }) : nodes = _list(nodes),
       dependencies = _list(dependencies) {
    final ids = this.nodes.toSet();
    if (ids.length != this.nodes.length) {
      throw ArgumentError('Reference graph nodes must be unique');
    }
    if (this.dependencies.any(
      (e) => !ids.contains(e.from) || !ids.contains(e.to),
    )) {
      throw ArgumentError('Reference graph dependency has unknown endpoint');
    }
    if (_cyclic(ids, this.dependencies)) {
      throw ArgumentError('Reference dependency graph must be acyclic');
    }
  }
  final List<String> nodes;
  final List<ReferenceDependency> dependencies;
  static bool _cyclic(Set<String> ids, List<ReferenceDependency> edges) {
    final outgoing = {for (final id in ids) id: <String>[]};
    for (final edge in edges) {
      outgoing[edge.from]!.add(edge.to);
    }
    final active = <String>{}, done = <String>{};
    bool visit(String id) {
      if (active.contains(id)) {
        return true;
      }
      if (done.contains(id)) {
        return false;
      }
      active.add(id);
      for (final next in outgoing[id]!) {
        if (visit(next)) {
          return true;
        }
      }
      active.remove(id);
      done.add(id);
      return false;
    }

    return ids.any(visit);
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes,
    'dependencies': dependencies.map((e) => e.toJson()).toList(),
    'acyclic': true,
  };
}

class DatumSuggestion {
  const DatumSuggestion({
    required this.label,
    required this.referenceId,
    required this.confidence,
    required this.justification,
  });
  final DatumLabel label;
  final String referenceId, justification;
  final double confidence;
  Map<String, dynamic> toJson() => {
    'datum': label.name.toUpperCase(),
    'referenceId': referenceId,
    'confidence': confidence,
    'justification': justification,
    'created': false,
  };
}

class CoordinateSystemSuggestion {
  const CoordinateSystemSuggestion({
    required this.referenceId,
    required this.originReferenceId,
    required this.orientationReferenceIds,
    required this.confidence,
    required this.justification,
    required this.alignmentStrategy,
  });
  final String referenceId, originReferenceId, justification, alignmentStrategy;
  final List<String> orientationReferenceIds;
  final double confidence;
  Map<String, dynamic> toJson() => {
    'referenceId': referenceId,
    'originReferenceId': originReferenceId,
    'orientationReferenceIds': orientationReferenceIds,
    'confidence': confidence,
    'justification': justification,
    'alignmentStrategy': alignmentStrategy,
    'created': false,
  };
}

class AlignmentStrategy {
  AlignmentStrategy({
    required this.id,
    required Iterable<String> steps,
    required this.confidence,
    required this.justification,
    required Iterable<String> evidenceIds,
  }) : steps = _list(steps),
       evidenceIds = _list(evidenceIds);
  final String id, justification;
  final List<String> steps, evidenceIds;
  final double confidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'steps': steps,
    'confidence': confidence,
    'justification': justification,
    'evidenceIds': evidenceIds,
    'applied': false,
  };
}

class ReferenceDecision {
  const ReferenceDecision({
    required this.referenceId,
    required this.type,
    required this.reason,
    required this.sequence,
  });
  final String referenceId, reason;
  final ReferenceDecisionType type;
  final int sequence;
  Map<String, dynamic> toJson() => {
    'referenceId': referenceId,
    'type': type.name,
    'reason': reason,
    'sequence': sequence,
  };
}

class SmartReferenceSession {
  SmartReferenceSession({
    required this.id,
    required this.context,
    required Iterable<ReferenceCandidate> candidates,
    required this.graph,
    required Iterable<DatumSuggestion> datums,
    required Iterable<CoordinateSystemSuggestion> coordinateSystems,
    required Iterable<AlignmentStrategy> strategies,
    required Iterable<ReferenceDecision> decisions,
  }) : candidates = _list(candidates),
       datums = _list(datums),
       coordinateSystems = _list(coordinateSystems),
       strategies = _list(strategies),
       decisions = _list(decisions);
  final String id;
  final EngineeringContextSnapshot context;
  final List<ReferenceCandidate> candidates;
  final ReferenceDependencyGraph graph;
  final List<DatumSuggestion> datums;
  final List<CoordinateSystemSuggestion> coordinateSystems;
  final List<AlignmentStrategy> strategies;
  final List<ReferenceDecision> decisions;
  SmartReferenceSession copyWith({Iterable<ReferenceDecision>? decisions}) =>
      SmartReferenceSession(
        id: id,
        context: context,
        candidates: candidates,
        graph: graph,
        datums: datums,
        coordinateSystems: coordinateSystems,
        strategies: strategies,
        decisions: decisions ?? this.decisions,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context.toJson(),
    'candidates': candidates.map((e) => e.toJson()).toList(),
    'graph': graph.toJson(),
    'datums': datums.map((e) => e.toJson()).toList(),
    'coordinateSystems': coordinateSystems.map((e) => e.toJson()).toList(),
    'strategies': strategies.map((e) => e.toJson()).toList(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'automaticCreation': false,
    'geometryModified': false,
  };
}
