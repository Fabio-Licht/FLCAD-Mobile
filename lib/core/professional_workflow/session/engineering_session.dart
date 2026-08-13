enum SessionEventType { decision, command, error, learning, automation }

class EngineeringSessionEvent {
  const EngineeringSessionEvent({
    required this.timestamp,
    required this.type,
    required this.name,
    required this.duration,
    this.accepted,
    this.metadata = const {},
  });
  final DateTime timestamp;
  final SessionEventType type;
  final String name;
  final Duration duration;
  final bool? accepted;
  final Map<String, dynamic> metadata;
}

class WorkflowProductivity {
  const WorkflowProductivity({
    required this.elapsed,
    required this.estimatedTimeSaved,
    required this.operationsAvoided,
    required this.automationsUsed,
    required this.acceptanceRate,
  });
  final Duration elapsed, estimatedTimeSaved;
  final int operationsAvoided, automationsUsed;
  final double acceptanceRate;
}

class EngineeringWorkflowSession {
  EngineeringWorkflowSession({
    required this.id,
    required this.projectId,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();
  final String id, projectId;
  final DateTime startedAt;
  final List<EngineeringSessionEvent> _events = [];
  List<EngineeringSessionEvent> get events => List.unmodifiable(_events);
  void record(
    SessionEventType type,
    String name, {
    Duration duration = Duration.zero,
    bool? accepted,
    Map<String, dynamic> metadata = const {},
  }) => _events.add(
    EngineeringSessionEvent(
      timestamp: DateTime.now(),
      type: type,
      name: name,
      duration: duration,
      accepted: accepted,
      metadata: metadata,
    ),
  );
  WorkflowProductivity analytics({DateTime? at}) {
    final decisions = _events
        .where((event) => event.type == SessionEventType.decision)
        .toList();
    final accepted = decisions.where((event) => event.accepted == true).length;
    final automations = _events
        .where((event) => event.type == SessionEventType.automation)
        .length;
    return WorkflowProductivity(
      elapsed: (at ?? DateTime.now()).difference(startedAt),
      estimatedTimeSaved: Duration(minutes: automations * 2),
      operationsAvoided: automations * 3,
      automationsUsed: automations,
      acceptanceRate: decisions.isEmpty ? 0 : accepted / decisions.length,
    );
  }
}
