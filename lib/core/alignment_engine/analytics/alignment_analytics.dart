class AlignmentAnalytics {
  int alignments = 0,
      bestFits = 0,
      icp = 0,
      rollbacks = 0,
      undo = 0,
      redo = 0,
      successes = 0,
      failures = 0,
      previewUpdates = 0,
      dependencyUpdates = 0,
      totalMicros = 0;
  double totalAccuracy = 0, maximumAccuracy = 0;
  double get averageTime => alignments == 0 ? 0 : totalMicros / alignments;
  double get averageAccuracy => successes == 0 ? 0 : totalAccuracy / successes;
  double get successRate =>
      successes + failures == 0 ? 0 : successes / (successes + failures);
  Map<String, dynamic> toJson() => {
    'alignments': alignments,
    'averageTime': averageTime,
    'bestFits': bestFits,
    'icp': icp,
    'rollback': rollbacks,
    'undo': undo,
    'redo': redo,
    'averageAccuracy': averageAccuracy,
    'maximumAccuracy': maximumAccuracy,
    'successRate': successRate,
    'previewUpdates': previewUpdates,
    'dependencyUpdates': dependencyUpdates,
  };
}
