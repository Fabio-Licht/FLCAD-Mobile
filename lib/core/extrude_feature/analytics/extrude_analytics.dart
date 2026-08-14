class ExtrudeAnalytics {
  int extrudes = 0,
      rebuilds = 0,
      failures = 0,
      undo = 0,
      redo = 0,
      rollback = 0,
      kernelAvailable = 0,
      successes = 0,
      parameterUpdates = 0,
      dependencyUpdates = 0,
      totalRebuildMicros = 0;
  double totalDistance = 0;
  double get averageDistance => extrudes == 0 ? 0 : totalDistance / extrudes;
  double get averageRebuildMicros =>
      rebuilds == 0 ? 0 : totalRebuildMicros / rebuilds;
  double get successRate => rebuilds == 0 ? 0 : successes / rebuilds;
  Map<String, dynamic> toJson() => {
    'extrudes': extrudes,
    'averageDistance': averageDistance,
    'averageRebuildMicros': averageRebuildMicros,
    'failures': failures,
    'undo': undo,
    'redo': redo,
    'rollback': rollback,
    'kernelAvailability': kernelAvailable,
    'featureSuccessRate': successRate,
    'parameterUpdates': parameterUpdates,
    'dependencyUpdates': dependencyUpdates,
  };
}
