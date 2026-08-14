class SketchAnalytics {
  int entities = 0;
  int selections = 0;
  int edits = 0;
  int undo = 0;
  int redo = 0;
  int sketches = 0;
  int constructionEntities = 0;
  int referenceEntities = 0;
  double get averageSketchSize => sketches == 0 ? 0 : entities / sketches;
  double get averageEntityCount => averageSketchSize;
  double get constructionRatio =>
      entities == 0 ? 0 : constructionEntities / entities;
  double get referenceRatio => entities == 0 ? 0 : referenceEntities / entities;
  Map<String, dynamic> toJson() => {
    'entities': entities,
    'selections': selections,
    'edits': edits,
    'undo': undo,
    'redo': redo,
    'sketches': sketches,
    'averageSketchSize': averageSketchSize,
    'averageEntityCount': averageEntityCount,
    'constructionRatio': constructionRatio,
    'referenceRatio': referenceRatio,
  };
}
