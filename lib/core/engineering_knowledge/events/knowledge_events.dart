import 'dart:async';

class KnowledgeEvent {
  const KnowledgeEvent(this.type, this.entityId, this.timestamp, this.payload);
  final String type, entityId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class KnowledgeEventBus {
  final _controller = StreamController<KnowledgeEvent>.broadcast();
  Stream<KnowledgeEvent> get events => _controller.stream;
  void publish(KnowledgeEvent event) => _controller.add(event);
  Future<void> close() => _controller.close();
}
