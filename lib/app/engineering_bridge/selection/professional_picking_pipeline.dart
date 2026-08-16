import '../contracts/bridge_selection.dart';
import 'camera_picking.dart';
import 'mesh_bvh.dart';
import 'mesh_hit_testing.dart';

class ProfessionalPickingPipeline {
  const ProfessionalPickingPipeline({
    this.camera = const CameraPicking(),
    this.hitTesting = const MeshHitTesting(),
  });
  final CameraPicking camera;
  final MeshHitTesting hitTesting;
  MeshHit? pick({
    required double screenX,
    required double screenY,
    required CameraPickingContext cameraContext,
    required BridgeSelection mesh,
    required MeshBvh spatialIndex,
  }) {
    final ray = camera.ray(
      screenX: screenX,
      screenY: screenY,
      camera: cameraContext,
    );
    return hitTesting.hit(spatialIndex.candidates(mesh, ray), ray);
  }
}
