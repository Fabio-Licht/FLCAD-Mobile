import '../../ai_engineering/models/ai_engineering_models.dart';
import '../../geometric_recognition/models/recognition_models.dart';

enum PrimitiveFunction {
  base,
  support,
  reference,
  symmetry,
  machining,
  free,
  mainAxis,
  hole,
  guide,
  bearing,
  revolution,
  draft,
  centering,
  tool,
  seat,
  joint,
  functionalRadius,
}

enum PrimitiveDecisionType { accepted, rejected }

enum SymmetryKind { x, y, z, radial, local, partial }

enum PatternKind {
  linear,
  circular,
  matrix,
  repeatedHoles,
  repeatedGrooves,
  bosses,
  pockets,
}

List<T> _list<T>(Iterable<T> value) => List<T>.unmodifiable(value);
Map<K, V> _map<K, V>(Map<K, V> value) => Map<K, V>.unmodifiable(value);

class PrimitiveObservation {
  PrimitiveObservation({
    required this.id,
    required this.type,
    required Map<String, double> measures,
    required Map<String, List<double>> vectors,
    required Iterable<String> adjacentIds,
    required this.recognitionConfidence,
  }) : measures = _map(measures),
       vectors = _map(vectors.map((key, value) => MapEntry(key, _list(value)))),
       adjacentIds = _list(adjacentIds);
  final String id;
  final PrimitiveType type;
  final Map<String, double> measures;
  final Map<String, List<double>> vectors;
  final List<String> adjacentIds;
  final double recognitionConfidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'measures': measures,
    'vectors': vectors,
    'adjacentIds': adjacentIds,
    'recognitionConfidence': recognitionConfidence,
  };
  factory PrimitiveObservation.fromJson(Map<String, dynamic> json) =>
      PrimitiveObservation(
        id: json['id'] as String,
        type: PrimitiveType.values.byName(json['type'] as String),
        measures: (json['measures'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        vectors: (json['vectors'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            (v as List<dynamic>).cast<num>().map((n) => n.toDouble()).toList(),
          ),
        ),
        adjacentIds: (json['adjacentIds'] as List<dynamic>).cast<String>(),
        recognitionConfidence: (json['recognitionConfidence'] as num)
            .toDouble(),
      );
}

class PrimitiveEvidence {
  const PrimitiveEvidence({
    required this.field,
    required this.value,
    required this.source,
    required this.justification,
  });
  final String field, source, justification;
  final Object value;
  Map<String, dynamic> toJson() => {
    'field': field,
    'value': value,
    'source': source,
    'justification': justification,
  };
}

class AlignmentSuggestion {
  AlignmentSuggestion({
    required Iterable<double> currentOrientation,
    required this.suggestedOrientation,
    required Map<String, double> angularDeviation,
    required this.angularError,
    required this.confidence,
    required this.justification,
  }) : currentOrientation = _list(currentOrientation),
       angularDeviation = _map(angularDeviation);
  final List<double> currentOrientation;
  final String suggestedOrientation, justification;
  final Map<String, double> angularDeviation;
  final double angularError, confidence;
  Map<String, dynamic> toJson() => {
    'currentOrientation': currentOrientation,
    'suggestedOrientation': suggestedOrientation,
    'angularDeviationDegrees': angularDeviation,
    'angularErrorDegrees': angularError,
    'confidence': confidence,
    'justification': justification,
    'applied': false,
  };
}

class AxisHypothesis {
  AxisHypothesis({
    required List<double> axis,
    required this.function,
    required this.confidence,
    required Iterable<String> relatedPrimitiveIds,
  }) : axis = _list(axis),
       relatedPrimitiveIds = _list(relatedPrimitiveIds);
  final List<double> axis;
  final String function;
  final double confidence;
  final List<String> relatedPrimitiveIds;
  Map<String, dynamic> toJson() => {
    'axis': axis,
    'function': function,
    'confidence': confidence,
    'relatedPrimitiveIds': relatedPrimitiveIds,
    'created': false,
  };
}

class SymmetryHypothesis {
  const SymmetryHypothesis({
    required this.kind,
    required this.score,
    required this.justification,
  });
  final SymmetryKind kind;
  final double score;
  final String justification;
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'score': score,
    'justification': justification,
    'mirrorCreated': false,
  };
}

class PatternHypothesis {
  PatternHypothesis({
    required this.kind,
    required Iterable<String> memberIds,
    required this.score,
    required this.justification,
  }) : memberIds = _list(memberIds);
  final PatternKind kind;
  final List<String> memberIds;
  final double score;
  final String justification;
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'memberIds': memberIds,
    'score': score,
    'justification': justification,
  };
}

class PrimitiveScores {
  const PrimitiveScores({
    required this.confidence,
    required this.importance,
    required this.manufacturingRelevance,
    required this.alignmentRelevance,
    required this.reconstructionRelevance,
    required this.overall,
  });
  final double confidence,
      importance,
      manufacturingRelevance,
      alignmentRelevance,
      reconstructionRelevance,
      overall;
  Map<String, dynamic> toJson() => {
    'confidence': confidence,
    'importance': importance,
    'manufacturingRelevance': manufacturingRelevance,
    'alignmentRelevance': alignmentRelevance,
    'reconstructionRelevance': reconstructionRelevance,
    'overall': overall,
  };
}

class PrimitiveHypothesis {
  PrimitiveHypothesis({
    required this.id,
    required this.primitive,
    required this.function,
    required this.scores,
    required Iterable<PrimitiveEvidence> evidence,
    required this.justification,
    required this.suggestion,
    this.alignment,
    this.axis,
    this.symmetry,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id, justification, suggestion;
  final PrimitiveObservation primitive;
  final PrimitiveFunction function;
  final PrimitiveScores scores;
  final List<PrimitiveEvidence> evidence;
  final AlignmentSuggestion? alignment;
  final AxisHypothesis? axis;
  final SymmetryHypothesis? symmetry;
  Map<String, dynamic> toJson() => {
    'id': id,
    'primitive': primitive.toJson(),
    'classification': function.name,
    'probableFunction': function.name,
    'scores': scores.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'justification': justification,
    'suggestion': suggestion,
    'alignment': alignment?.toJson(),
    'axis': axis?.toJson(),
    'symmetry': symmetry?.toJson(),
    'geometryModified': false,
  };
}

class PrimitiveDecision {
  const PrimitiveDecision({
    required this.hypothesisId,
    required this.type,
    required this.reason,
    required this.sequence,
  });
  final String hypothesisId, reason;
  final PrimitiveDecisionType type;
  final int sequence;
  Map<String, dynamic> toJson() => {
    'hypothesisId': hypothesisId,
    'type': type.name,
    'reason': reason,
    'sequence': sequence,
  };
}

class PrimitiveRecommendation {
  PrimitiveRecommendation({
    required this.id,
    required this.hypothesisId,
    required this.text,
    required this.justification,
    required Iterable<PrimitiveEvidence> evidence,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id, hypothesisId, text, justification;
  final List<PrimitiveEvidence> evidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'hypothesisId': hypothesisId,
    'text': text,
    'justification': justification,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'consultative': true,
    'executesCommands': false,
    'createsEntities': false,
    'geometryModified': false,
  };
}

class PrimitiveIntelligenceSession {
  PrimitiveIntelligenceSession({
    required this.id,
    required this.context,
    required Iterable<PrimitiveHypothesis> hypotheses,
    required Iterable<PatternHypothesis> patterns,
    required Iterable<PrimitiveDecision> decisions,
  }) : hypotheses = _list(hypotheses),
       patterns = _list(patterns),
       decisions = _list(decisions);
  final String id;
  final EngineeringContextSnapshot context;
  final List<PrimitiveHypothesis> hypotheses;
  final List<PatternHypothesis> patterns;
  final List<PrimitiveDecision> decisions;
  PrimitiveIntelligenceSession copyWith({
    Iterable<PrimitiveDecision>? decisions,
  }) => PrimitiveIntelligenceSession(
    id: id,
    context: context,
    hypotheses: hypotheses,
    patterns: patterns,
    decisions: decisions ?? this.decisions,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context.toJson(),
    'hypotheses': hypotheses.map((e) => e.toJson()).toList(),
    'patterns': patterns.map((e) => e.toJson()).toList(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'automaticCommands': false,
    'geometryModified': false,
  };
}
