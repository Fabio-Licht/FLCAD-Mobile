enum EngineeringIntentType {
  alignment,
  reconstruction,
  modeling,
  manufacturing,
  inspection,
  cam,
}

enum IntentDecisionType { accepted, rejected }

enum RecommendationPriority { low, medium, high, critical }

enum IntentSessionState { active, completed }

List<T> _list<T>(Iterable<T> value) => List<T>.unmodifiable(value);
Map<K, V> _map<K, V>(Map<K, V> value) => Map<K, V>.unmodifiable(value);

class IntentEvidence {
  const IntentEvidence({
    required this.source,
    required this.description,
    required this.value,
  });
  final String source;
  final String description;
  final double value;
  Map<String, dynamic> toJson() => {
    'source': source,
    'description': description,
    'value': value,
  };
  factory IntentEvidence.fromJson(Map<String, dynamic> json) => IntentEvidence(
    source: json['source'] as String,
    description: json['description'] as String,
    value: (json['value'] as num).toDouble(),
  );
}

class IntentScore {
  const IntentScore({
    required this.geometricScore,
    required this.topologyScore,
    required this.manufacturingScore,
    required this.continuityScore,
    required this.symmetryScore,
    required this.historyScore,
    required this.userPreferenceScore,
    required this.overallConfidence,
  });
  final double geometricScore;
  final double topologyScore;
  final double manufacturingScore;
  final double continuityScore;
  final double symmetryScore;
  final double historyScore;
  final double userPreferenceScore;
  final double overallConfidence;
  Map<String, dynamic> toJson() => {
    'geometricScore': geometricScore,
    'topologyScore': topologyScore,
    'manufacturingScore': manufacturingScore,
    'continuityScore': continuityScore,
    'symmetryScore': symmetryScore,
    'historyScore': historyScore,
    'userPreferenceScore': userPreferenceScore,
    'overallConfidence': overallConfidence,
  };
  factory IntentScore.fromJson(Map<String, dynamic> json) => IntentScore(
    geometricScore: (json['geometricScore'] as num).toDouble(),
    topologyScore: (json['topologyScore'] as num).toDouble(),
    manufacturingScore: (json['manufacturingScore'] as num).toDouble(),
    continuityScore: (json['continuityScore'] as num).toDouble(),
    symmetryScore: (json['symmetryScore'] as num).toDouble(),
    historyScore: (json['historyScore'] as num).toDouble(),
    userPreferenceScore: (json['userPreferenceScore'] as num).toDouble(),
    overallConfidence: (json['overallConfidence'] as num).toDouble(),
  );
}

class IntentConfidence {
  IntentConfidence({required this.score, required Map<String, double> weights})
    : weights = _map(weights);
  final IntentScore score;
  final Map<String, double> weights;
  Map<String, dynamic> toJson() => {
    'score': score.toJson(),
    'weights': weights,
  };
  factory IntentConfidence.fromJson(Map<String, dynamic> json) =>
      IntentConfidence(
        score: IntentScore.fromJson(json['score'] as Map<String, dynamic>),
        weights: (json['weights'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
}

class IntentCandidate {
  IntentCandidate({
    required this.id,
    required this.type,
    required this.title,
    required this.rationale,
    required Iterable<IntentEvidence> evidence,
    required this.confidence,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id;
  final EngineeringIntentType type;
  final String title;
  final String rationale;
  final List<IntentEvidence> evidence;
  final IntentConfidence confidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'rationale': rationale,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'confidence': confidence.toJson(),
  };
  factory IntentCandidate.fromJson(Map<String, dynamic> json) =>
      IntentCandidate(
        id: json['id'] as String,
        type: EngineeringIntentType.values.byName(json['type'] as String),
        title: json['title'] as String,
        rationale: json['rationale'] as String,
        evidence: (json['evidence'] as List<dynamic>).map(
          (e) => IntentEvidence.fromJson(e as Map<String, dynamic>),
        ),
        confidence: IntentConfidence.fromJson(
          json['confidence'] as Map<String, dynamic>,
        ),
      );
}

class EngineeringIntent {
  EngineeringIntent({
    required this.id,
    required this.sessionId,
    required Iterable<IntentCandidate> candidates,
  }) : candidates = _list(candidates);
  final String id;
  final String sessionId;
  final List<IntentCandidate> candidates;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'candidates': candidates.map((e) => e.toJson()).toList(),
  };
  factory EngineeringIntent.fromJson(Map<String, dynamic> json) =>
      EngineeringIntent(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        candidates: (json['candidates'] as List<dynamic>).map(
          (e) => IntentCandidate.fromJson(e as Map<String, dynamic>),
        ),
      );
}

class IntentSuggestion {
  const IntentSuggestion({
    required this.candidateId,
    required this.text,
    required this.technicalJustification,
  });
  final String candidateId;
  final String text;
  final String technicalJustification;
  Map<String, dynamic> toJson() => {
    'candidateId': candidateId,
    'text': text,
    'technicalJustification': technicalJustification,
    'consultative': true,
  };
}

class AIRecommendation {
  AIRecommendation({
    required this.id,
    required this.candidateId,
    required this.priority,
    required this.suggestion,
    required Iterable<IntentEvidence> evidence,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id;
  final String candidateId;
  final RecommendationPriority priority;
  final IntentSuggestion suggestion;
  final List<IntentEvidence> evidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'candidateId': candidateId,
    'priority': priority.name,
    'suggestion': suggestion.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'executesCommands': false,
    'geometryModified': false,
  };
}

class IntentDecision {
  const IntentDecision({
    required this.candidateId,
    required this.type,
    required this.reason,
    required this.sequence,
  });
  final String candidateId;
  final IntentDecisionType type;
  final String reason;
  final int sequence;
  Map<String, dynamic> toJson() => {
    'candidateId': candidateId,
    'type': type.name,
    'reason': reason,
    'sequence': sequence,
  };
  factory IntentDecision.fromJson(Map<String, dynamic> json) => IntentDecision(
    candidateId: json['candidateId'] as String,
    type: IntentDecisionType.values.byName(json['type'] as String),
    reason: json['reason'] as String,
    sequence: json['sequence'] as int,
  );
}

class IntentHistory {
  IntentHistory(Iterable<IntentDecision> decisions)
    : decisions = _list(decisions);
  final List<IntentDecision> decisions;
  Map<String, dynamic> toJson() => {
    'decisions': decisions.map((e) => e.toJson()).toList(),
  };
  factory IntentHistory.fromJson(Map<String, dynamic> json) => IntentHistory(
    (json['decisions'] as List<dynamic>).map(
      (e) => IntentDecision.fromJson(e as Map<String, dynamic>),
    ),
  );
}

class EngineeringContextSnapshot {
  EngineeringContextSnapshot({
    required this.projectId,
    required this.activePartId,
    required Map<String, dynamic> values,
  }) : values = _map(values);
  final String projectId;
  final String activePartId;
  final Map<String, dynamic> values;
  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'activePartId': activePartId,
    'values': values,
  };
  factory EngineeringContextSnapshot.fromJson(Map<String, dynamic> json) =>
      EngineeringContextSnapshot(
        projectId: json['projectId'] as String,
        activePartId: json['activePartId'] as String,
        values: json['values'] as Map<String, dynamic>,
      );
}

class IntentSession {
  IntentSession({
    required this.id,
    required this.context,
    required this.intent,
    required this.history,
    required this.state,
  });
  final String id;
  final EngineeringContextSnapshot context;
  final EngineeringIntent intent;
  final IntentHistory history;
  final IntentSessionState state;
  IntentSession copyWith({IntentHistory? history, IntentSessionState? state}) =>
      IntentSession(
        id: id,
        context: context,
        intent: intent,
        history: history ?? this.history,
        state: state ?? this.state,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context.toJson(),
    'intent': intent.toJson(),
    'history': history.toJson(),
    'state': state.name,
    'automaticDecisions': false,
    'geometryModified': false,
  };
  factory IntentSession.fromJson(Map<String, dynamic> json) => IntentSession(
    id: json['id'] as String,
    context: EngineeringContextSnapshot.fromJson(
      json['context'] as Map<String, dynamic>,
    ),
    intent: EngineeringIntent.fromJson(json['intent'] as Map<String, dynamic>),
    history: IntentHistory.fromJson(json['history'] as Map<String, dynamic>),
    state: IntentSessionState.values.byName(json['state'] as String),
  );
}
