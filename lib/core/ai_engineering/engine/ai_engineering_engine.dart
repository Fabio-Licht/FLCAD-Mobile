import '../advisor/ai_advisor.dart';
import '../analytics/ai_engineering_analytics.dart';
import '../context/engineering_context.dart';
import '../integration/ai_engineering_integration.dart';
import '../intent/engineering_intent_engine.dart';
import '../models/ai_engineering_models.dart';
import '../repository/engineering_intent_repository.dart';

class AIEngineeringEngine {
  AIEngineeringEngine({
    required this.intentEngine,
    required this.repository,
    this.advisor = const AIAdvisor(),
    this.integration,
  });
  final EngineeringIntentEngine intentEngine;
  final EngineeringIntentRepository repository;
  final AIAdvisor advisor;
  final AIEngineeringIntegration? integration;

  IntentSession start({
    required String sessionId,
    required EngineeringContext context,
    required Iterable<EngineeringIntentType> requestedIntents,
  }) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId');
    }
    final intent = intentEngine.interpret(
      sessionId: sessionId,
      context: context,
      requestedIntents: requestedIntents,
    );
    final session = IntentSession(
      id: sessionId,
      context: context.snapshot(),
      intent: intent,
      history: IntentHistory(const []),
      state: IntentSessionState.active,
    );
    repository.add(session);
    integration?.onSessionChanged(session);
    return session;
  }

  IntentSession decide({
    required String sessionId,
    required String candidateId,
    required IntentDecisionType decision,
    required String reason,
  }) {
    final current = _require(sessionId);
    if (current.state != IntentSessionState.active) {
      throw StateError('Session is not active: $sessionId');
    }
    if (!current.intent.candidates.any((e) => e.id == candidateId)) {
      throw StateError('Unknown candidate: $candidateId');
    }
    final decisions = [...current.history.decisions];
    decisions.add(
      IntentDecision(
        candidateId: candidateId,
        type: decision,
        reason: reason,
        sequence: decisions.length,
      ),
    );
    final updated = current.copyWith(history: IntentHistory(decisions));
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  IntentSession complete(String sessionId) {
    final completed = _require(
      sessionId,
    ).copyWith(state: IntentSessionState.completed);
    repository.update(completed);
    integration?.onSessionChanged(completed);
    return completed;
  }

  IntentSession rollback(String sessionId, int decisionCount) {
    final restored = repository.rollback(sessionId, decisionCount);
    integration?.onSessionChanged(restored);
    return restored;
  }

  List<AIRecommendation> recommendations(String sessionId) =>
      advisor.advise(_require(sessionId).intent);
  AIEngineeringAnalytics analytics(
    String sessionId, {
    Duration analysisDuration = Duration.zero,
  }) => AIEngineeringAnalytics.fromSession(
    _require(sessionId),
    analysisDuration: analysisDuration,
  );
  Future<void> persist(String sessionId) => repository.persist(
    sessionId,
    recommendations: recommendations(sessionId),
    analytics: analytics(sessionId),
  );
  IntentSession _require(String id) {
    final value = repository.find(id);
    if (value == null) throw StateError('Unknown AI Engineering session: $id');
    return value;
  }
}
