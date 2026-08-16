// ignore_for_file: curly_braces_in_flow_control_structures

import '../../../core/reference_engine/models/reference_entity.dart';
import '../../../core/reference_engine/models/reference_geometry.dart';
import '../../../core/sketch_engine/api/sketch_engine_api.dart';
import '../../../core/sketch_engine/models/sketch_models.dart';
import '../contracts/bridge_context.dart';
import '../contracts/bridge_validation.dart';

class SketchBridge {
  const SketchBridge(this.api, {this.validation = const BridgeValidation()});
  final SketchEngineApi api;
  final BridgeValidation validation;
  Sketch openFromApprovedPlane({
    required BridgeContext context,
    required ReferenceEntity plane,
    required String name,
  }) {
    validation.requireConfirmation(context);
    if (plane.geometry is! PlaneGeometry)
      throw StateError('A valid plane reference is required to open a sketch.');
    final geometry = plane.geometry as PlaneGeometry;
    final sketch = api.createSketch(
      name,
      plane: SketchPlane(
        type: SketchPlaneType.faceReference,
        parameters: {
          'referenceId': plane.id,
          'origin': geometry.origin.toJson(),
          'normal': geometry.normal.toJson(),
        },
      ),
    );
    api.openSketch(sketch.id);
    return sketch;
  }

  void undo(Sketch sketch) => api.deleteSketch(sketch.id);
}
