// ignore_for_file: curly_braces_in_flow_control_structures

import '../../../core/reference_engine/models/reference_entity.dart';
import '../../../core/reference_engine/models/reference_geometry.dart';
import '../../../core/smart_regions/models/geometry.dart';
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
    if (plane.geometry is! PlaneGeometry) {
      throw StateError('A valid plane reference is required to open a sketch.');
    }
    return openFromPlaneGeometry(
      context: context,
      referenceId: plane.id,
      geometry: plane.geometry as PlaneGeometry,
      name: name,
    );
  }

  Sketch openFromPlaneGeometry({
    required BridgeContext context,
    required String referenceId,
    required PlaneGeometry geometry,
    required String name,
  }) {
    validation.requireConfirmation(context);
    final normal = geometry.normal.normalized;
    final xAxis =
        (geometry.xDirection ??
                normal.cross(
                  normal.z.abs() < .9
                      ? const Vec3(0, 0, 1)
                      : const Vec3(0, 1, 0),
                ))
            .normalized;
    final yAxis = normal.cross(xAxis).normalized;
    SketchVector vector(Vec3 value) => SketchVector(value.x, value.y, value.z);
    final sketch = api.createSketch(
      name,
      plane: SketchPlane(
        type: SketchPlaneType.faceReference,
        parameters: {
          'referenceId': referenceId,
          'origin': geometry.origin.toJson(),
          'normal': geometry.normal.toJson(),
          'xDirection': xAxis.toJson(),
        },
      ),
      coordinates: SketchCoordinateSystem(
        origin: vector(geometry.origin),
        xAxis: vector(xAxis),
        yAxis: vector(yAxis),
        normal: vector(normal),
      ),
    );
    api.openSketch(sketch.id);
    return sketch;
  }

  void undo(Sketch sketch) => api.deleteSketch(sketch.id);
}
