import '../../engineering/runtime/engineering_runtime.dart';
import '../../engineering_cognition/models/cognition_models.dart';
import '../models/reconstruction_models.dart';
import '../planner/master_planner.dart';

class AutonomousCancellationToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  void check() {
    if (_cancelled) {
      throw StateError('Autonomous reconstruction planning cancelled');
    }
  }
}

class AutonomousReconstructionRuntime {
  const AutonomousReconstructionRuntime();
  Future<ReconstructionWorkflow> plan(
    CognitionSnapshot cognition, {
    AutonomousCancellationToken? cancellation,
  }) async {
    cancellation?.check();
    final result = await EngineeringRuntime.shared
        .submit(
          'reconstruction:${DateTime.now().microsecondsSinceEpoch}',
          () => const ReconstructionMasterPlanner().build(
            ReconstructionPlanInput(cognition),
          ),
          namespace: 'reconstruction',
        )
        .future;
    cancellation?.check();
    return result;
  }
}
