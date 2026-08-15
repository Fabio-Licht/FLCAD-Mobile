import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../reconstruction_strategy/models/reconstruction_strategy_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../analytics/interactive_assistant_analytics.dart';
import '../awareness/context_awareness_engine.dart';
import '../conversation/engineering_conversation_layer.dart';
import '../guidance/assistant_guidance_engines.dart';
import '../integration/interactive_assistant_integration.dart';
import '../models/interactive_assistant_models.dart';
import '../repository/interactive_assistant_repository.dart';

class InteractiveEngineeringAssistantEngine {
  InteractiveEngineeringAssistantEngine({
    required this.repository,
    this.contextAwareness = const ContextAwarenessEngine(),
    this.conversation = const EngineeringConversationLayer(),
    this.questions = const EngineeringQuestionEngine(),
    this.progressAssistant = const ReconstructionProgressAssistant(),
    this.alertEngine = const EngineeringAlertEngine(),
    this.suggestionEngine = const EngineeringSuggestionEngine(),
    this.comparator = const MultiStrategyComparator(),
    this.integration,
  });
  final InteractiveAssistantRepository repository;
  final ContextAwarenessEngine contextAwareness;
  final EngineeringConversationLayer conversation;
  final EngineeringQuestionEngine questions;
  final ReconstructionProgressAssistant progressAssistant;
  final EngineeringAlertEngine alertEngine;
  final EngineeringSuggestionEngine suggestionEngine;
  final MultiStrategyComparator comparator;
  final InteractiveAssistantIntegration? integration;
  final Map<
    String,
    (
      EngineeringFeatureSession,
      SmartReferenceSession,
      ReconstructionStrategySession,
    )
  >
  _sources = {};

  InteractiveAssistantSession start({
    required String sessionId,
    required EngineeringFeatureSession features,
    required SmartReferenceSession references,
    required ReconstructionStrategySession strategies,
  }) {
    if (features.context.projectId != references.context.projectId ||
        features.context.projectId != strategies.context.projectId) {
      throw StateError('Assistant sources belong to different projects');
    }
    final timeline = <EngineeringTimelineEvent>[
      EngineeringTimelineEvent(
        id: '$sessionId:event:0',
        sequence: 0,
        event: 'Part loaded.',
        source: 'project',
      ),
      EngineeringTimelineEvent(
        id: '$sessionId:event:1',
        sequence: 1,
        event: 'Recognition completed.',
        source: 'Recognition',
      ),
      EngineeringTimelineEvent(
        id: '$sessionId:event:2',
        sequence: 2,
        event: 'Primitive Intelligence completed.',
        source: 'Primitive Intelligence',
      ),
      EngineeringTimelineEvent(
        id: '$sessionId:event:3',
        sequence: 3,
        event: 'Feature Intelligence completed.',
        source: 'Engineering Feature Intelligence',
      ),
      EngineeringTimelineEvent(
        id: '$sessionId:event:4',
        sequence: 4,
        event: 'Smart References completed.',
        source: 'Smart Reference System',
      ),
      EngineeringTimelineEvent(
        id: '$sessionId:event:5',
        sequence: 5,
        event: 'Engineering Playbook activated.',
        source: 'Reconstruction Strategy AI',
      ),
    ];
    final context = contextAwareness.build(
      features: features,
      references: references,
      strategies: strategies,
      sessionHistory: timeline.map((e) => e.event),
    );
    final messages = conversation.messages(
      sessionId,
      features,
      references,
      strategies,
    );
    final evidence = messages.expand((e) => e.evidence).toSet().toList();
    final progress = progressAssistant.build(strategies);
    final initial = InteractiveAssistantSession(
      id: sessionId,
      context: context,
      messages: messages,
      progress: progress,
      alerts: alertEngine.build(sessionId, references, strategies, evidence),
      suggestions: suggestionEngine.build(
        sessionId,
        references,
        strategies,
        progress,
        evidence,
      ),
      comparisons: comparator.compare(strategies),
      timeline: timeline,
      decisions: const [],
      snapshots: const [],
    );
    final snapshot = _snapshot(
      initial,
      references.toJson(),
      strategies.toJson(),
      strategies.playbook.toJson(),
    );
    final session = initial.copyWith(snapshots: [snapshot]);
    _sources[sessionId] = (features, references, strategies);
    repository.add(session);
    integration?.onSessionChanged(session);
    return session;
  }

  EngineeringAnswer answer(String sessionId, EngineeringQuestion question) {
    _require(sessionId);
    final source = _sources[sessionId];
    if (source == null) {
      throw StateError('Assistant source context is not loaded: $sessionId');
    }
    return questions.answer(question, source.$1, source.$2, source.$3);
  }

  InteractiveAssistantSession decide({
    required String sessionId,
    required String suggestionId,
    required SuggestionDecisionType type,
    required String reason,
  }) {
    final current = _require(sessionId);
    if (!current.suggestions.any((e) => e.id == suggestionId)) {
      throw StateError('Unknown engineering suggestion: $suggestionId');
    }
    final decisions = [
      ...current.decisions,
      SuggestionDecision(
        suggestionId: suggestionId,
        type: type,
        reason: reason,
        sequence: current.decisions.length,
      ),
    ];
    final timeline = [
      ...current.timeline,
      EngineeringTimelineEvent(
        id: '$sessionId:event:${current.timeline.length}',
        sequence: current.timeline.length,
        event: 'Suggestion $suggestionId ${type.name}.',
        source: 'user',
      ),
    ];
    var updated = current.copyWith(
      context: _context(current.context, timeline),
      timeline: timeline,
      decisions: decisions,
    );
    updated = updated.copyWith(
      snapshots: [...updated.snapshots, _snapshotFromPrevious(updated)],
    );
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  InteractiveAssistantSession completeStep(
    String sessionId,
    String stepId,
    String reason,
  ) {
    final current = _require(sessionId);
    if (!current.progress.any((e) => e.stepId == stepId)) {
      throw StateError('Unknown progress step: $stepId');
    }
    final ordered = [...current.progress]
      ..sort((a, b) => a.order.compareTo(b.order));
    final completed = {
      ...ordered
          .where((e) => e.state == ProgressState.completed)
          .map((e) => e.stepId),
      stepId,
    };
    var assigned = false;
    final progress = ordered.map((item) {
      final state = completed.contains(item.stepId)
          ? ProgressState.completed
          : !assigned
          ? ProgressState.inProgress
          : ProgressState.pending;
      if (state == ProgressState.inProgress) {
        assigned = true;
      }
      return ReconstructionProgressItem(
        stepId: item.stepId,
        objective: item.objective,
        state: state,
        order: item.order,
      );
    }).toList();
    final timeline = [
      ...current.timeline,
      EngineeringTimelineEvent(
        id: '$sessionId:event:${current.timeline.length}',
        sequence: current.timeline.length,
        event:
            '${ordered.singleWhere((e) => e.stepId == stepId).objective} completed: $reason',
        source: 'user',
      ),
    ];
    var updated = current.copyWith(
      context: _context(current.context, timeline),
      progress: progress,
      timeline: timeline,
    );
    updated = updated.copyWith(
      snapshots: [...updated.snapshots, _snapshotFromPrevious(updated)],
    );
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  InteractiveAssistantSession rollback(String id, int snapshotSequence) {
    final value = repository.rollback(id, snapshotSequence);
    integration?.onSessionChanged(value);
    return value;
  }

  InteractiveAssistantAnalytics analytics(
    String id, {
    Duration responseDuration = Duration.zero,
  }) => InteractiveAssistantAnalytics.fromSession(
    _require(id),
    responseDuration: responseDuration,
  );
  Future<void> persist(String id) => repository.persist(id, analytics(id));
  AssistantSessionSnapshot _snapshot(
    InteractiveAssistantSession session,
    Map<String, dynamic> references,
    Map<String, dynamic> strategies,
    Map<String, dynamic> playbook,
  ) => AssistantSessionSnapshot(
    id: '${session.id}:snapshot:${session.snapshots.length}',
    sequence: session.snapshots.length,
    context: session.context,
    playbook: playbook,
    references: references,
    strategies: strategies,
    history: session.timeline,
    analytics: InteractiveAssistantAnalytics.fromSession(session).toJson(),
  );
  AssistantSessionSnapshot _snapshotFromPrevious(
    InteractiveAssistantSession session,
  ) {
    final previous = session.snapshots.last;
    return _snapshot(
      session,
      previous.references,
      previous.strategies,
      previous.playbook,
    );
  }

  AssistantContext _context(
    AssistantContext value,
    List<EngineeringTimelineEvent> timeline,
  ) => AssistantContext(
    projectId: value.projectId,
    activePartId: value.activePartId,
    loadedPart: value.loadedPart,
    primitiveCount: value.primitiveCount,
    featureCount: value.featureCount,
    referenceCount: value.referenceCount,
    activePlaybookId: value.activePlaybookId,
    activeStrategyId: value.activeStrategyId,
    currentStepId: value.currentStepId,
    projectObjectives: value.projectObjectives,
    sessionHistory: timeline.map((e) => e.event),
  );
  InteractiveAssistantSession _require(String id) {
    final value = repository.find(id);
    if (value == null) {
      throw StateError('Unknown interactive assistant session: $id');
    }
    return value;
  }
}
