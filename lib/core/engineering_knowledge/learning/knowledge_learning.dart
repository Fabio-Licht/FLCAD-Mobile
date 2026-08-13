class EngineeringLearningSample {
  const EngineeringLearningSample(
    this.projectId,
    this.entityId,
    this.assertion,
    this.accepted,
    this.timestamp,
    this.context,
  );
  final String projectId, entityId, assertion;
  final bool accepted;
  final DateTime timestamp;
  final Map<String, dynamic> context;
}

abstract interface class KnowledgeLearningStore {
  Future<void> save(EngineeringLearningSample sample);
  Future<List<EngineeringLearningSample>> query(String assertion);
}

class InMemoryKnowledgeLearningStore implements KnowledgeLearningStore {
  final List<EngineeringLearningSample> _samples = [];
  @override
  Future<void> save(EngineeringLearningSample sample) async =>
      _samples.add(sample);
  @override
  Future<List<EngineeringLearningSample>> query(String assertion) async =>
      List.unmodifiable(_samples.where((s) => s.assertion == assertion));
}

class KnowledgeLearningEngine {
  const KnowledgeLearningEngine(this.store);
  final KnowledgeLearningStore store;
  Future<void> learn(EngineeringLearningSample sample) => store.save(sample);
  Future<double?> observedAcceptance(String assertion) async {
    final values = await store.query(assertion);
    if (values.isEmpty) return null;
    return values.where((v) => v.accepted).length / values.length;
  }
}
