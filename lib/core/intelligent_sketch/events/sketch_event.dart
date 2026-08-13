enum SketchEventType {
  created,
  updated,
  deleted,
  solved,
  projected,
  recognized,
  converted,
}

class SketchEvent {
  const SketchEvent(
    this.type,
    this.sketchId,
    this.projectId,
    this.timestamp,
    this.payload,
  );
  final SketchEventType type;
  final String sketchId, projectId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class SketchEventBus {
  final _listeners = <void Function(SketchEvent)>[];
  void subscribe(void Function(SketchEvent) listener) =>
      _listeners.add(listener);
  void publish(SketchEvent event) {
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }
}
