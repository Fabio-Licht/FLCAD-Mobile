enum AssistantMessageKind { analysis, suggestion, observation, answer }

enum ProgressState { completed, inProgress, pending }

enum AlertSeverity { information, warning, critical }

enum SuggestionDecisionType { accepted, rejected }

enum EngineeringQuestion {
  whyPlane,
  whyAxis,
  whyStrategy,
  whichEvidence,
  whichFeature,
  whichReference,
}

List<T> _list<T>(Iterable<T> value) => List<T>.unmodifiable(value);
Map<K, V> _map<K, V>(Map<K, V> value) => Map<K, V>.unmodifiable(value);

class AssistantEvidence {
  AssistantEvidence({
    required this.id,
    required this.source,
    required this.description,
    required Iterable<String> entityIds,
    required this.score,
  }) : entityIds = _list(entityIds) {
    if (this.entityIds.isEmpty) {
      throw ArgumentError.value(entityIds, 'entityIds', 'must not be empty');
    }
  }
  final String id, source, description;
  final List<String> entityIds;
  final double score;
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'description': description,
    'entityIds': entityIds,
    'score': score,
  };
}

class AssistantContext {
  AssistantContext({
    required this.projectId,
    required this.activePartId,
    required this.loadedPart,
    required this.primitiveCount,
    required this.featureCount,
    required this.referenceCount,
    required this.activePlaybookId,
    required this.activeStrategyId,
    required this.currentStepId,
    required Iterable<String> projectObjectives,
    required Iterable<String> sessionHistory,
  }) : projectObjectives = _list(projectObjectives),
       sessionHistory = _list(sessionHistory);
  final String projectId, activePartId, activePlaybookId, activeStrategyId;
  final String? loadedPart, currentStepId;
  final int primitiveCount, featureCount, referenceCount;
  final List<String> projectObjectives, sessionHistory;
  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'activePartId': activePartId,
    'loadedPart': loadedPart,
    'primitiveCount': primitiveCount,
    'featureCount': featureCount,
    'referenceCount': referenceCount,
    'activePlaybookId': activePlaybookId,
    'activeStrategyId': activeStrategyId,
    'currentStepId': currentStepId,
    'projectObjectives': projectObjectives,
    'sessionHistory': sessionHistory,
    'externalContextUsed': false,
  };
}

class EngineeringMessage {
  EngineeringMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.confidence,
    required Iterable<AssistantEvidence> evidence,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }
  final String id, title, body;
  final AssistantMessageKind kind;
  final double confidence;
  final List<AssistantEvidence> evidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    'confidence': confidence,
    'evidence': evidence.map((e) => e.toJson()).toList(),
  };
}

class ReconstructionProgressItem {
  const ReconstructionProgressItem({
    required this.stepId,
    required this.objective,
    required this.state,
    required this.order,
  });
  final String stepId, objective;
  final ProgressState state;
  final int order;
  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'objective': objective,
    'state': state.name,
    'order': order,
  };
}

class EngineeringAlert {
  EngineeringAlert({
    required this.id,
    required this.severity,
    required this.message,
    required this.justification,
    required Iterable<AssistantEvidence> evidence,
  }) : evidence = _list(evidence);
  final String id, message, justification;
  final AlertSeverity severity;
  final List<AssistantEvidence> evidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'severity': severity.name,
    'message': message,
    'justification': justification,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'consultative': true,
  };
}

class EngineeringSuggestion {
  EngineeringSuggestion({
    required this.id,
    required this.action,
    required this.justification,
    required this.confidence,
    required Iterable<AssistantEvidence> evidence,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty || justification.trim().isEmpty) {
      throw ArgumentError(
        'Suggestion requires evidence and technical justification',
      );
    }
  }
  final String id, action, justification;
  final double confidence;
  final List<AssistantEvidence> evidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'justification': justification,
    'confidence': confidence,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'requiresApproval': true,
    'executed': false,
    'geometryModified': false,
  };
}

class StrategyComparison {
  const StrategyComparison({
    required this.strategyId,
    required this.name,
    required this.precision,
    required this.estimatedMinutes,
    required this.complexity,
    required this.confidence,
  });
  final String strategyId, name;
  final double precision, complexity, confidence;
  final int estimatedMinutes;
  Map<String, dynamic> toJson() => {
    'strategyId': strategyId,
    'name': name,
    'precision': precision,
    'estimatedMinutes': estimatedMinutes,
    'complexity': complexity,
    'confidence': confidence,
  };
}

class EngineeringAnswer {
  EngineeringAnswer({
    required this.question,
    required this.answer,
    required Iterable<AssistantEvidence> evidence,
  }) : evidence = _list(evidence) {
    if (this.evidence.isEmpty) {
      throw ArgumentError('Engineering answer requires evidence');
    }
  }
  final EngineeringQuestion question;
  final String answer;
  final List<AssistantEvidence> evidence;
  Map<String, dynamic> toJson() => {
    'question': question.name,
    'answer': answer,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'externalContextUsed': false,
  };
}

class EngineeringTimelineEvent {
  const EngineeringTimelineEvent({
    required this.id,
    required this.sequence,
    required this.event,
    required this.source,
  });
  final String id, event, source;
  final int sequence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sequence': sequence,
    'logicalTime': sequence,
    'event': event,
    'source': source,
  };
}

class SuggestionDecision {
  const SuggestionDecision({
    required this.suggestionId,
    required this.type,
    required this.reason,
    required this.sequence,
  });
  final String suggestionId, reason;
  final SuggestionDecisionType type;
  final int sequence;
  Map<String, dynamic> toJson() => {
    'suggestionId': suggestionId,
    'type': type.name,
    'reason': reason,
    'sequence': sequence,
  };
}

class AssistantSessionSnapshot {
  AssistantSessionSnapshot({
    required this.id,
    required this.sequence,
    required this.context,
    required Map<String, dynamic> playbook,
    required Map<String, dynamic> references,
    required Map<String, dynamic> strategies,
    required Iterable<EngineeringTimelineEvent> history,
    required Map<String, dynamic> analytics,
  }) : playbook = _map(playbook),
       references = _map(references),
       strategies = _map(strategies),
       history = _list(history),
       analytics = _map(analytics);
  final String id;
  final int sequence;
  final AssistantContext context;
  final Map<String, dynamic> playbook, references, strategies, analytics;
  final List<EngineeringTimelineEvent> history;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sequence': sequence,
    'context': context.toJson(),
    'playbook': playbook,
    'references': references,
    'strategies': strategies,
    'history': history.map((e) => e.toJson()).toList(),
    'analytics': analytics,
  };
}

class InteractiveAssistantSession {
  InteractiveAssistantSession({
    required this.id,
    required this.context,
    required Iterable<EngineeringMessage> messages,
    required Iterable<ReconstructionProgressItem> progress,
    required Iterable<EngineeringAlert> alerts,
    required Iterable<EngineeringSuggestion> suggestions,
    required Iterable<StrategyComparison> comparisons,
    required Iterable<EngineeringTimelineEvent> timeline,
    required Iterable<SuggestionDecision> decisions,
    required Iterable<AssistantSessionSnapshot> snapshots,
  }) : messages = _list(messages),
       progress = _list(progress),
       alerts = _list(alerts),
       suggestions = _list(suggestions),
       comparisons = _list(comparisons),
       timeline = _list(timeline),
       decisions = _list(decisions),
       snapshots = _list(snapshots);
  final String id;
  final AssistantContext context;
  final List<EngineeringMessage> messages;
  final List<ReconstructionProgressItem> progress;
  final List<EngineeringAlert> alerts;
  final List<EngineeringSuggestion> suggestions;
  final List<StrategyComparison> comparisons;
  final List<EngineeringTimelineEvent> timeline;
  final List<SuggestionDecision> decisions;
  final List<AssistantSessionSnapshot> snapshots;
  InteractiveAssistantSession copyWith({
    AssistantContext? context,
    Iterable<ReconstructionProgressItem>? progress,
    Iterable<EngineeringTimelineEvent>? timeline,
    Iterable<SuggestionDecision>? decisions,
    Iterable<AssistantSessionSnapshot>? snapshots,
  }) => InteractiveAssistantSession(
    id: id,
    context: context ?? this.context,
    messages: messages,
    progress: progress ?? this.progress,
    alerts: alerts,
    suggestions: suggestions,
    comparisons: comparisons,
    timeline: timeline ?? this.timeline,
    decisions: decisions ?? this.decisions,
    snapshots: snapshots ?? this.snapshots,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context.toJson(),
    'messages': messages.map((e) => e.toJson()).toList(),
    'progress': progress.map((e) => e.toJson()).toList(),
    'alerts': alerts.map((e) => e.toJson()).toList(),
    'suggestions': suggestions.map((e) => e.toJson()).toList(),
    'comparisons': comparisons.map((e) => e.toJson()).toList(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'snapshots': snapshots.map((e) => e.toJson()).toList(),
    'automaticCommands': false,
    'geometryModified': false,
  };
}
