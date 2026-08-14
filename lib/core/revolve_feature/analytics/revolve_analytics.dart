class RevolveAnalytics {
  int revolves = 0,
      rebuilds = 0,
      kernelAvailable = 0,
      rollbacks = 0,
      undo = 0,
      redo = 0,
      failures = 0,
      successes = 0,
      parameterUpdates = 0,
      axisUpdates = 0,
      dependencyUpdates = 0,
      totalRebuildMicros = 0;
  double totalAngle = 0;
  double get averageAngle => revolves == 0 ? 0 : totalAngle / revolves;
  double get averageRebuildMicros =>
      rebuilds == 0 ? 0 : totalRebuildMicros / rebuilds;
  double get successRate => rebuilds == 0 ? 0 : successes / rebuilds;
  Map<String, dynamic> toJson() => {
    'revolveCount': revolves,
    'averageAngle': averageAngle,
    'averageRebuild': averageRebuildMicros,
    'kernelAvailability': kernelAvailable,
    'rollbacks': rollbacks,
    'undo': undo,
    'redo': redo,
    'failures': failures,
    'successRate': successRate,
    'parameterUpdates': parameterUpdates,
    'axisUpdates': axisUpdates,
    'dependencyUpdates': dependencyUpdates,
  };
}
