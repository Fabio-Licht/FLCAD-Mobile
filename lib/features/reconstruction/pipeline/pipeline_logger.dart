import '../models/pipeline_event.dart';

class PipelineLogger {
  PipelineLogger(this.onEvent);
  final void Function(PipelineEvent event) onEvent;

  void event(
    PipelineEventType type,
    String message, {
    String? stepId,
    Duration? duration,
    Object? error,
  }) => onEvent(
    PipelineEvent(
      type: type,
      timestamp: DateTime.now(),
      message: message,
      stepId: stepId,
      durationMs: duration?.inMilliseconds,
      error: error?.toString(),
    ),
  );
}
