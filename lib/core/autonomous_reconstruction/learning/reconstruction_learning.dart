class ReconstructionFeedback {
  const ReconstructionFeedback(
    this.projectId,
    this.workflowId,
    this.stageId,
    this.originalAction,
    this.userAction,
    this.timestamp,
  );
  final String projectId, workflowId, stageId, originalAction, userAction;
  final DateTime timestamp;
}

abstract interface class ReconstructionLearningStore {
  Future<void> save(ReconstructionFeedback feedback);
  Future<List<ReconstructionFeedback>> forStage(String stageId);
}

class InMemoryReconstructionLearningStore
    implements ReconstructionLearningStore {
  final List<ReconstructionFeedback> _values = [];
  @override
  Future<void> save(ReconstructionFeedback value) async => _values.add(value);
  @override
  Future<List<ReconstructionFeedback>> forStage(String id) async =>
      List.unmodifiable(_values.where((v) => v.stageId == id));
}

class AutonomousReconstructionLearning {
  const AutonomousReconstructionLearning(this.store);
  final ReconstructionLearningStore store;
  Future<void> learn(ReconstructionFeedback feedback) => store.save(feedback);
  Future<double> preference(String stageId) async {
    final values = await store.forStage(stageId);
    if (values.isEmpty) return 0;
    return (values.where((v) => v.userAction == 'accepted').length -
            values.where((v) => v.userAction == 'rejected').length) /
        values.length;
  }
}
