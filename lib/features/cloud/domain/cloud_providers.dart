import '../../reconstruction/pipeline/pipeline_context.dart';

abstract interface class CloudSyncProvider {
  Future<void> synchronize(PipelineContext context);
}

abstract interface class RemoteProcessingProvider {
  Future<void> process(PipelineContext context);
}
