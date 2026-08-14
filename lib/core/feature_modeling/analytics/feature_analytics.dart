class FeatureAnalytics {
  int featureCount = 0,
      suppressedFeatures = 0,
      dependencies = 0,
      rebuildCount = 0,
      totalRebuildMicros = 0,
      rollbackCount = 0,
      failures = 0,
      quality = 100;
  double averageDependencyDepth = 0;
  double get averageRebuildTimeMicros =>
      rebuildCount == 0 ? 0 : totalRebuildMicros / rebuildCount;
  Map<String, dynamic> toJson() => {
    'featureCount': featureCount,
    'suppressedFeatures': suppressedFeatures,
    'dependencies': dependencies,
    'averageRebuildTimeMicros': averageRebuildTimeMicros,
    'averageDependencyDepth': averageDependencyDepth,
    'rollbackCount': rollbackCount,
    'failures': failures,
    'quality': quality,
  };
}
