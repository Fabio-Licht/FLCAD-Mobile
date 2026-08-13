class SurfaceLearningEvent {
  const SurfaceLearningEvent(
    this.projectId,
    this.surfaceId,
    this.decision,
    this.timestamp,
    this.context,
  );
  final String projectId, surfaceId, decision;
  final DateTime timestamp;
  final Map<String, dynamic> context;
}

abstract interface class SurfaceLearningSink {
  Future<void> record(SurfaceLearningEvent event);
}

class NoOpSurfaceLearningSink implements SurfaceLearningSink {
  const NoOpSurfaceLearningSink();
  @override
  Future<void> record(SurfaceLearningEvent event) async {}
}
