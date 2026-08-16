import '../../modeling/interaction/interaction_context.dart';
import '../../modeling/viewport/viewport_controller.dart';

class BridgeViewportSync {
  const BridgeViewportSync(this.viewport);
  final ModelingViewportController viewport;
  void selected(ModelingSelection selection) => viewport.select(selection);
  void preview(EngineeringPreview preview) => viewport.showPreview(preview);
  void committed() => viewport.clearPreview();
}
