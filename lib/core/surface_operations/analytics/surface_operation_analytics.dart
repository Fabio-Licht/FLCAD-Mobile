class SurfaceOperationsAnalytics {
  int operations = 0,
      commits = 0,
      rollbacks = 0,
      cancellations = 0,
      validationErrors = 0,
      topologyUpdates = 0,
      continuityUpdates = 0;
  Duration totalExecution = Duration.zero;
  Duration get averageExecution => operations == 0
      ? Duration.zero
      : Duration(microseconds: totalExecution.inMicroseconds ~/ operations);
  Map<String, dynamic> toJson() => {
    'operations': operations,
    'averageExecutionMicros': averageExecution.inMicroseconds,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'validationErrors': validationErrors,
    'topologyUpdates': topologyUpdates,
    'continuityUpdates': continuityUpdates,
  };
}
