import '../models/pipeline_event.dart';
import '../models/pipeline_progress.dart';
import '../models/pipeline_result.dart';
import '../pipeline/pipeline_context.dart';

abstract interface class ReconstructionBackend {
  Future<PipelineResult> run(
    PipelineContext context, {
    required void Function(PipelineProgress progress) onProgress,
    required void Function(PipelineEvent event) onEvent,
  });
  void cancel();
  Future<void> dispose();
}
