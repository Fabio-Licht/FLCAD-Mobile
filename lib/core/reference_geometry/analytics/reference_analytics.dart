class ReferenceAnalytics {
  int planes = 0,
      axes = 0,
      points = 0,
      coordinateSystems = 0,
      rebuilds = 0,
      undo = 0,
      redo = 0,
      failures = 0,
      successes = 0,
      dependencyUpdates = 0,
      visibilityChanges = 0,
      totalMicros = 0;
  double get averageMicros => rebuilds == 0 ? 0 : totalMicros / rebuilds;
  double get successRate => rebuilds == 0 ? 0 : successes / rebuilds;
  Map<String, dynamic> toJson() => {
    'planes': planes,
    'axes': axes,
    'points': points,
    'coordinateSystems': coordinateSystems,
    'averageTime': averageMicros,
    'rebuilds': rebuilds,
    'undo': undo,
    'redo': redo,
    'failures': failures,
    'successRate': successRate,
    'dependencyUpdates': dependencyUpdates,
    'visibilityChanges': visibilityChanges,
  };
}
