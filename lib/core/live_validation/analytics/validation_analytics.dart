class ValidationAnalytics {
  int sessions = 0,
      incrementalUpdates = 0,
      heatMaps = 0,
      featureUpdates = 0,
      datumUpdates = 0,
      alignmentUpdates = 0,
      snapshots = 0,
      rollbacks = 0,
      timelineUpdates = 0,
      advisorUpdates = 0,
      successes = 0,
      failures = 0;
  double totalQuality = 0;
  double get averageQuality => successes == 0 ? 0 : totalQuality / successes;
  double get successRate =>
      successes + failures == 0 ? 0 : successes / (successes + failures);
  Map<String, dynamic> toJson() => {
    'sessions': sessions,
    'incrementalUpdates': incrementalUpdates,
    'heatMaps': heatMaps,
    'featureUpdates': featureUpdates,
    'datumUpdates': datumUpdates,
    'alignmentUpdates': alignmentUpdates,
    'snapshots': snapshots,
    'rollbacks': rollbacks,
    'timelineUpdates': timelineUpdates,
    'advisorUpdates': advisorUpdates,
    'averageQuality': averageQuality,
    'successRate': successRate,
  };
}
