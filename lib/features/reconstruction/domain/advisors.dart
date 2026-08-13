import '../pipeline/pipeline_context.dart';

abstract interface class QualityAdvisor {
  Future<void> advise(PipelineContext context);
}

abstract interface class ReconstructionAdvisor {
  Future<void> advise(PipelineContext context);
}

abstract interface class PipelineAdvisor {
  Future<void> advise(PipelineContext context);
}
