enum PipelineEventType {
  pipelineStarted,
  pipelineFinished,
  stepStarted,
  stepFinished,
  stepFailed,
  log,
}

class PipelineEvent {
  const PipelineEvent({
    required this.type,
    required this.timestamp,
    required this.message,
    this.stepId,
    this.durationMs,
    this.error,
  });
  final PipelineEventType type;
  final DateTime timestamp;
  final String message;
  final String? stepId;
  final int? durationMs;
  final String? error;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'stepId': stepId,
    'durationMs': durationMs,
    'error': error,
  };
  factory PipelineEvent.fromJson(Map<String, dynamic> json) => PipelineEvent(
    type: PipelineEventType.values.firstWhere(
      (value) => value.name == json['type'],
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    message: json['message'] as String,
    stepId: json['stepId'] as String?,
    durationMs: json['durationMs'] as int?,
    error: json['error'] as String?,
  );
}
