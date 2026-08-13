import 'dart:async';

class CognitionEvent {
  const CognitionEvent(this.type, this.entityId, this.timestamp, this.payload);
  final String type, entityId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class CognitionEventBus {
  final _events = StreamController<CognitionEvent>.broadcast();
  Stream<CognitionEvent> get events => _events.stream;
  void publish(CognitionEvent event) => _events.add(event);
  Future<void> close() => _events.close();
}
