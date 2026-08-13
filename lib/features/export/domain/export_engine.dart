import '../../reconstruction/pipeline/pipeline_context.dart';

/// Extension point for future project-owned exports.
abstract interface class ExportEngine {
  Future<String> export(PipelineContext context);
}
