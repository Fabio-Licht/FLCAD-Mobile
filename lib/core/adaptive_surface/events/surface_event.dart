enum SurfaceEventType {
  created,
  updated,
  deleted,
  rebuilt,
  refined,
  validated,
  repaired,
  optimized,
  recognized,
}

class SurfaceEvent {
  const SurfaceEvent(
    this.type,
    this.surfaceId,
    this.projectId,
    this.timestamp,
    this.payload,
  );
  final SurfaceEventType type;
  final String surfaceId, projectId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class SurfaceEventBus {
  final _listeners = <void Function(SurfaceEvent)>[];
  void subscribe(void Function(SurfaceEvent) value) => _listeners.add(value);
  void publish(SurfaceEvent event) {
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }
}
