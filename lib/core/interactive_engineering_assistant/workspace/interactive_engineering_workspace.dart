import '../analytics/interactive_assistant_analytics.dart';
import '../models/interactive_assistant_models.dart';

class InteractiveEngineeringWorkspace {
  const InteractiveEngineeringWorkspace({
    required this.session,
    required this.analytics,
  });
  final InteractiveAssistantSession session;
  final InteractiveAssistantAnalytics analytics;
  List<String> get panels => const [
    'Assistant',
    'Progress',
    'Alerts',
    'Suggestions',
    'Frequently Asked Questions',
    'Timeline',
    'Strategies',
    'Engineering Assistant',
  ];
  Map<String, dynamic> get propertyInspector {
    final next = session.progress
        .where((e) => e.state == ProgressState.inProgress)
        .firstOrNull;
    final active = session.comparisons.isEmpty
        ? null
        : session.comparisons.first;
    return {
      'Panel': 'Engineering Assistant',
      'Context': session.context.toJson(),
      'Active Strategy': active?.toJson(),
      'Next Step': next?.toJson(),
      'Confidence': active?.confidence,
      'Recommendations': session.suggestions.map((e) => e.toJson()).toList(),
      'Justifications': session.messages.map((e) => e.toJson()).toList(),
      'Timeline': session.timeline.map((e) => e.toJson()).toList(),
      'Analytics': analytics.toJson(),
      'Geometry Modified': false,
    };
  }
}
