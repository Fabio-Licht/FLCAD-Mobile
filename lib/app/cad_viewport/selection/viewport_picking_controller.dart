import 'package:flutter/painting.dart';

import '../../../core/cad_kernel/io/kernel_io_models.dart';
import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../../engineering_bridge/contracts/bridge_selection.dart';
import '../../engineering_bridge/selection/camera_picking.dart';
import '../../engineering_bridge/selection/mesh_bvh.dart';
import '../../engineering_bridge/selection/professional_picking_pipeline.dart';
import '../camera/cad_camera_controller.dart';
import '../scene/cad_scene_graph.dart';

class CadViewportPick {
  const CadViewportPick({required this.entityId, required this.hit});
  final String entityId;
  final MeshHit hit;
}

class ViewportPickingController {
  final Map<String, MeshBvh> _indexes = {};
  final ProfessionalPickingPipeline pipeline =
      const ProfessionalPickingPipeline();

  CadViewportPick? pick({
    required Offset position,
    required CadCameraController camera,
    required CadSceneGraph scene,
  }) {
    CadViewportPick? nearest;
    for (final entity in scene.entities.where(
      (item) =>
          item.visible &&
          item.geometry['nodes'] is List &&
          item.geometry['triangles'] is List,
    )) {
      final nodes = (entity.geometry['nodes'] as List).cast<num>();
      final triangles = (entity.geometry['triangles'] as List).cast<num>();
      final geometry = KernelMeshGeometry(
        nodes: nodes.map((value) => value.toDouble()).toList(growable: false),
        triangles: triangles
            .map((value) => value.toInt())
            .toList(growable: false),
      );
      if (triangles.isEmpty) continue;
      final index = _indexes.putIfAbsent(entity.id, () => MeshBvh(geometry));
      final selection = BridgeSelection(
        id: '${entity.id}:mesh',
        entityId: entity.id,
        kind: BridgeSelectionKind.triangle,
        geometry: geometry,
        triangleIndices: Set.from(
          List.generate(triangles.length ~/ 3, (triangle) => triangle),
        ),
      );
      final rowMajor = camera.inverseViewProjectionMatrix.values;
      final columnMajor = [
        for (var column = 0; column < 4; column++)
          for (var row = 0; row < 4; row++) rowMajor[row * 4 + column],
      ];
      final hit = pipeline.pick(
        screenX: position.dx,
        screenY: position.dy,
        cameraContext: CameraPickingContext(
          viewportWidth: camera.viewportWidth,
          viewportHeight: camera.viewportHeight,
          inverseViewProjection: columnMajor,
        ),
        mesh: selection,
        spatialIndex: index,
      );
      if (hit != null &&
          (nearest == null || hit.distance < nearest.hit.distance)) {
        nearest = CadViewportPick(entityId: entity.id, hit: hit);
      }
    }
    return nearest;
  }

  Vector3? pointOnPlane({
    required Offset position,
    required CadCameraController camera,
    required Vector3 origin,
    required Vector3 normal,
  }) {
    final ray = pipeline.camera.ray(
      screenX: position.dx,
      screenY: position.dy,
      camera: _cameraContext(camera),
    );
    final denominator = normal.dot(ray.direction);
    if (denominator.abs() < 1e-12) return null;
    final distance = normal.dot(origin - ray.origin) / denominator;
    if (distance < 0) return null;
    return ray.origin + ray.direction * distance;
  }

  CameraPickingContext _cameraContext(CadCameraController camera) {
    final rowMajor = camera.inverseViewProjectionMatrix.values;
    final columnMajor = [
      for (var column = 0; column < 4; column++)
        for (var row = 0; row < 4; row++) rowMajor[row * 4 + column],
    ];
    return CameraPickingContext(
      viewportWidth: camera.viewportWidth,
      viewportHeight: camera.viewportHeight,
      inverseViewProjection: columnMajor,
    );
  }
}
