import 'dart:async';

class AutonomousReconstructionEvent {
  const AutonomousReconstructionEvent(
    this.type,
    this.workflowId,
    this.timestamp,
    this.payload,
  );
  final String type, workflowId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}

class AutonomousReconstructionEventBus {
  final _controller =
      StreamController<AutonomousReconstructionEvent>.broadcast();
  Stream<AutonomousReconstructionEvent> get events => _controller.stream;
  void publish(AutonomousReconstructionEvent value) => _controller.add(value);
  Future<void> close() => _controller.close();
}
