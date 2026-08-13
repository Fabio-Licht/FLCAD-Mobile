class SketchLearningEvent {
  const SketchLearningEvent(
    this.projectId,
    this.sketchId,
    this.action,
    this.timestamp,
    this.metadata,
  );
  final String projectId, sketchId, action;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

abstract interface class SketchLearningSink {
  Future<void> record(SketchLearningEvent event);
}

class NoOpSketchLearningSink implements SketchLearningSink {
  const NoOpSketchLearningSink();
  @override
  Future<void> record(SketchLearningEvent event) async {}
}
