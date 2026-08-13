class EngineeringLearningRecord {
  const EngineeringLearningRecord(
    this.projectId,
    this.entityId,
    this.domain,
    this.action,
    this.timestamp,
    this.context,
  );
  final String projectId, entityId, domain, action;
  final DateTime timestamp;
  final Map<String, dynamic> context;
}

typedef EngineeringLearningSink =
    Future<void> Function(EngineeringLearningRecord record);

class EngineeringLearning {
  final List<EngineeringLearningSink> _sinks = [];
  void register(EngineeringLearningSink sink) => _sinks.add(sink);
  Future<void> record(EngineeringLearningRecord record) =>
      Future.wait(_sinks.map((s) => s(record)));
}
