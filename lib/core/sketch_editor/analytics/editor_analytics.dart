class EditorAnalytics {
  int editCount = 0,
      totalEditMicros = 0,
      entities = 0,
      selections = 0,
      undo = 0,
      redo = 0,
      movements = 0,
      conversions = 0,
      snapCount = 0,
      previewCount = 0,
      suggestionsAccepted = 0,
      suggestionsIgnored = 0,
      dofSamples = 0,
      totalDof = 0;
  int sketchQuality = 100;
  double get averageEditTimeMicros =>
      editCount == 0 ? 0 : totalEditMicros / editCount;
  double get averageDof => dofSamples == 0 ? 0 : totalDof / dofSamples;
  Map<String, dynamic> toJson() => {
    'averageEditTimeMicros': averageEditTimeMicros,
    'entities': entities,
    'selections': selections,
    'undo': undo,
    'redo': redo,
    'movements': movements,
    'conversions': conversions,
    'sketchQuality': sketchQuality,
    'averageDof': averageDof,
    'suggestionsAccepted': suggestionsAccepted,
    'suggestionsIgnored': suggestionsIgnored,
    'snapCount': snapCount,
    'previewCount': previewCount,
  };
}
