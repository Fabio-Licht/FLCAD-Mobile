class WorkflowAnalytics {
  int workflows = 0,
      opens = 0,
      pauses = 0,
      resumes = 0,
      snapshots = 0,
      restores = 0,
      replays = 0,
      undo = 0,
      redo = 0,
      checklistUpdates = 0,
      advisorUpdates = 0,
      timelineUpdates = 0,
      failures = 0,
      completions = 0;
  int totalDurationMicros = 0;
  double get completionRate => workflows == 0 ? 0 : completions / workflows;
  Map<String, dynamic> toJson() => {
    'workflows': workflows,
    'opens': opens,
    'pauses': pauses,
    'resumes': resumes,
    'snapshots': snapshots,
    'restores': restores,
    'replays': replays,
    'undo': undo,
    'redo': redo,
    'checklistUpdates': checklistUpdates,
    'advisorUpdates': advisorUpdates,
    'timelineUpdates': timelineUpdates,
    'failures': failures,
    'completionRate': completionRate,
    'totalDurationMicros': totalDurationMicros,
  };
}
