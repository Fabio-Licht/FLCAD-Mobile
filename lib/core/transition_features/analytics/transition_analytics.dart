class TransitionAnalytics {
  int sweeps = 0,
      lofts = 0,
      rebuilds = 0,
      failures = 0,
      successes = 0,
      kernelAvailable = 0,
      undo = 0,
      redo = 0,
      rollbacks = 0,
      parameterUpdates = 0,
      dependencyUpdates = 0,
      totalRebuildMicros = 0;
  double totalComplexity = 0;
  int get count => sweeps + lofts;
  double get averageRebuild =>
      rebuilds == 0 ? 0 : totalRebuildMicros / rebuilds;
  double get averageComplexity => count == 0 ? 0 : totalComplexity / count;
  double get successRate => rebuilds == 0 ? 0 : successes / rebuilds;
  Map<String, dynamic> toJson() => {
    'sweepCount': sweeps,
    'loftCount': lofts,
    'averageRebuild': averageRebuild,
    'averageComplexity': averageComplexity,
    'failures': failures,
    'kernelAvailability': kernelAvailable,
    'successRate': successRate,
    'undo': undo,
    'redo': redo,
    'rollback': rollbacks,
    'parameterUpdates': parameterUpdates,
    'dependencyUpdates': dependencyUpdates,
  };
}
