import 'pipeline_context.dart';

abstract interface class PipelineStep {
  String get id;
  String get name;
  Future<void> execute(PipelineContext context);
}

class PipelineCancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
