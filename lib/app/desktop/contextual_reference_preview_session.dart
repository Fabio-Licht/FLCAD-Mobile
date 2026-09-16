import '../cad_viewport/scene/cad_scene_graph.dart';
import '../runtime/cad_runtime.dart';

/// Owns the single transient preview used by the contextual reference launcher.
/// It never writes document state; Apply remains the responsibility of the
/// existing durable command selected by the user.
class ContextualReferencePreviewSession {
  ContextualReferencePreviewSession(this.runtime);

  static const id = 'preview:contextual-reference';
  final CadRuntime runtime;
  CadSceneEntity? _preview;

  bool get active => runtime.scene.find(id) != null;

  void show(CadSceneEntity value) {
    cancel();
    _preview = CadSceneEntity(
      id: id,
      kind: value.kind,
      geometry: value.geometry,
      transparent: true,
    );
    runtime.showTransient(_preview!);
  }

  void cancel() {
    if (_preview == null) return;
    runtime.hideTransient(id);
    _preview = null;
  }
}
