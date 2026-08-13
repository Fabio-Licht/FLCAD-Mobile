enum RegionEventType {
  created,
  updated,
  deleted,
  merged,
  split,
  recognized,
  exported,
  analyzed,
  rendered,
}

class RegionEvent {
  const RegionEvent({
    required this.type,
    required this.regionId,
    required this.projectId,
    required this.timestamp,
    required this.payload,
  });
  final RegionEventType type;
  final String regionId, projectId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'regionId': regionId,
    'projectId': projectId,
    'timestamp': timestamp.toIso8601String(),
    'payload': payload,
  };
}

class RegionEventBus {
  final _listeners = <void Function(RegionEvent)>[];
  void subscribe(void Function(RegionEvent) listener) =>
      _listeners.add(listener);
  void unsubscribe(void Function(RegionEvent) listener) =>
      _listeners.remove(listener);
  void publish(RegionEvent event) {
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }
}
