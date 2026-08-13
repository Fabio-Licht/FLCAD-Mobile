class TopologyLearningEvent {
  const TopologyLearningEvent(
    this.projectId,
    this.objectId,
    this.action,
    this.timestamp,
  );
  final String projectId, objectId, action;
  final DateTime timestamp;
}

abstract interface class TopologyLearningSink {
  Future<void> record(TopologyLearningEvent event);
}

class NoOpTopologyLearningSink implements TopologyLearningSink {
  const NoOpTopologyLearningSink();
  @override
  Future<void> record(TopologyLearningEvent event) async {}
}
