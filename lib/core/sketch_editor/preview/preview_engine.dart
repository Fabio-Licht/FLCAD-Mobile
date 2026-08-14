import '../analytics/editor_analytics.dart';
import '../models/editor_models.dart';

class PreviewEngine {
  PreviewEngine(this.analytics);
  final EditorAnalytics analytics;
  final Map<String, EditorOperation> _previews = {};
  List<EditorOperation> get active => List.unmodifiable(_previews.values);
  EditorOperation begin(EditorOperation operation) {
    operation.status = EditorOperationStatus.preview;
    _previews[operation.id] = operation;
    analytics.previewCount++;
    return operation;
  }

  EditorOperation confirm(String id) {
    final operation =
        _previews.remove(id) ?? (throw StateError('Unknown preview: $id'));
    operation.status = EditorOperationStatus.committed;
    return operation;
  }

  void cancel(String id) {
    final operation =
        _previews.remove(id) ?? (throw StateError('Unknown preview: $id'));
    operation.status = EditorOperationStatus.cancelled;
  }

  void clear() => _previews.clear();
}
