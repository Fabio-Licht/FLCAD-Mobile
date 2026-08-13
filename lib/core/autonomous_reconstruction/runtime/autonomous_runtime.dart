import 'dart:isolate';
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
    final result = await Isolate.run(
      () => const ReconstructionMasterPlanner().build(
        ReconstructionPlanInput(cognition),
      ),
    );
    cancellation?.check();
    return result;
  }
}
