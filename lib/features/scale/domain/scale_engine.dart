import '../../reconstruction/pipeline/pipeline_context.dart';

/// Extension point for a future scale engine. No automatic scale is performed in M-003.
abstract interface class ScaleEngine {
  Future<void> prepare(PipelineContext context);
}
