enum ReferenceEventType {
  created,
  updated,
  deleted,
  recognized,
  rebuilt,
  validated,
}

class ReferenceEvent {
  const ReferenceEvent(
    this.type,
    this.referenceId,
    this.projectId,
    this.timestamp,
    this.payload,
  );
  final ReferenceEventType type;
  final String referenceId, projectId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'referenceId': referenceId,
    'projectId': projectId,
    'timestamp': timestamp.toIso8601String(),
    'payload': payload,
  };
}

class ReferenceEventBus {
  final _listeners = <void Function(ReferenceEvent)>[];
  void subscribe(void Function(ReferenceEvent) listener) =>
      _listeners.add(listener);
  void publish(ReferenceEvent event) {
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }
}
