import '../models/interactive_models.dart';

class SelectionPreviewEngine {
  const SelectionPreviewEngine();
  SelectionPreview create(InteractiveSelection selection) => SelectionPreview(
    selectionId: selection.id,
    highlight: selection.localError > 0 ? 'error-overlay' : 'selection-overlay',
    bounds: selection.bounds,
    normal: selection.normal,
    area: selection.area,
    radius: selection.radius,
    curvature: selection.curvature,
    relatedFeature: selection.relatedFeature,
    localError: selection.localError,
    confidence: selection.confidence,
  );
}
