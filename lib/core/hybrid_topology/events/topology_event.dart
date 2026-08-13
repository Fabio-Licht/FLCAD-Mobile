enum TopologyEventType {
  created,
  layerAdded,
  morphed,
  compensated,
  repaired,
  validated,
  rebuilt,
  deleted,
}

class TopologyEvent {
  const TopologyEvent(
    this.type,
    this.objectId,
    this.projectId,
    this.timestamp,
    this.payload,
  );
  final TopologyEventType type;
  final String objectId, projectId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class TopologyEventBus {
  final _listeners = <void Function(TopologyEvent)>[];
  void subscribe(void Function(TopologyEvent) l) => _listeners.add(l);
  void publish(TopologyEvent e) {
    for (final l in List.of(_listeners)) {
      l(e);
    }
  }
}
