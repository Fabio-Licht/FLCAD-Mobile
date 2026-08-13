class CognitionFeedback {
  const CognitionFeedback(
    this.projectId,
    this.entityId,
    this.conclusion,
    this.action,
    this.timestamp,
  );
  final String projectId, entityId, conclusion, action;
  final DateTime timestamp;
}

abstract interface class CognitionLearningStore {
  Future<void> save(CognitionFeedback feedback);
  Future<List<CognitionFeedback>> forConclusion(String conclusion);
}

class InMemoryCognitionLearningStore implements CognitionLearningStore {
  final List<CognitionFeedback> _values = [];
  @override
  Future<void> save(CognitionFeedback value) async => _values.add(value);
  @override
  Future<List<CognitionFeedback>> forConclusion(String conclusion) async =>
      List.unmodifiable(_values.where((v) => v.conclusion == conclusion));
}

class CognitionLearningEngine {
  const CognitionLearningEngine(this.store);
  final CognitionLearningStore store;
  Future<void> record(CognitionFeedback feedback) => store.save(feedback);
  Future<double> confidenceAdjustment(String conclusion) async {
    final values = await store.forConclusion(conclusion);
    if (values.isEmpty) return 0;
    final score = values.fold<double>(
      0,
      (sum, v) =>
          sum +
          switch (v.action) {
            'accepted' => .02,
            'corrected' => -.04,
            'deleted' => -.03,
            _ => 0,
          },
    );
    return score.clamp(-.2, .2).toDouble();
  }
}
