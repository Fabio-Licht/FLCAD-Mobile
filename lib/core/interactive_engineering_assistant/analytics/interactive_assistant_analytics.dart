import '../models/interactive_assistant_models.dart';

class InteractiveAssistantAnalytics {
  const InteractiveAssistantAnalytics({
    required this.suggestionsIssued,
    required this.accepted,
    required this.rejected,
    required this.responseDuration,
    required this.contextProjection,
    required this.sessionHistoryCount,
  });
  final int suggestionsIssued, accepted, rejected, sessionHistoryCount;
  final Duration responseDuration;
  final Map<String, dynamic> contextProjection;
  factory InteractiveAssistantAnalytics.fromSession(
    InteractiveAssistantSession session, {
    Duration responseDuration = Duration.zero,
  }) => InteractiveAssistantAnalytics(
    suggestionsIssued: session.suggestions.length,
    accepted: session.decisions
        .where((e) => e.type == SuggestionDecisionType.accepted)
        .length,
    rejected: session.decisions
        .where((e) => e.type == SuggestionDecisionType.rejected)
        .length,
    responseDuration: responseDuration,
    contextProjection: session.context.toJson(),
    sessionHistoryCount: session.timeline.length,
  );
  Map<String, dynamic> toJson() => {
    'suggestionsIssued': suggestionsIssued,
    'accepted': accepted,
    'rejected': rejected,
    'responseMicros': responseDuration.inMicroseconds,
    'context': contextProjection,
    'sessionHistoryCount': sessionHistoryCount,
    'internalTimers': false,
  };
}
