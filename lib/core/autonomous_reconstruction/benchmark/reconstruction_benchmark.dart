import '../../engineering_cognition/models/cognition_models.dart';
import '../planner/master_planner.dart';
import '../models/reconstruction_models.dart';

class ReconstructionBenchmarkResult {
  const ReconstructionBenchmarkResult(this.elapsed, this.stageCount);
  final Duration elapsed;
  final int stageCount;
}

class ReconstructionBenchmark {
  const ReconstructionBenchmark();
  ReconstructionBenchmarkResult run(CognitionSnapshot cognition) {
    final watch = Stopwatch()..start(),
        workflow = const ReconstructionMasterPlanner().build(
          ReconstructionPlanInput(cognition),
        );
    watch.stop();
    return ReconstructionBenchmarkResult(watch.elapsed, workflow.stages.length);
  }
}
