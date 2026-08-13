enum ParametricEventType {
  featureCreated,
  featureUpdated,
  featureRebuilt,
  featureValidated,
  solidCreated,
  solidValidated,
  branchCreated,
  merged,
}

class ParametricEvent {
  const ParametricEvent(
    this.type,
    this.entityId,
    this.projectId,
    this.timestamp,
    this.payload,
  );
  final ParametricEventType type;
  final String entityId, projectId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class ParametricEventBus {
  final _listeners = <void Function(ParametricEvent)>[];
  void subscribe(void Function(ParametricEvent) l) => _listeners.add(l);
  void publish(ParametricEvent e) {
    for (final l in List.of(_listeners)) {
      l(e);
    }
  }
}
