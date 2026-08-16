import '../../../core/cad_kernel/io/kernel_io_models.dart';
import '../scene/cad_scene_graph.dart';

class MeshSceneAdapter {
  const MeshSceneAdapter._();

  static CadSceneEntity fromKernel({
    required String id,
    required KernelMeshGeometry geometry,
    required KernelBounds bounds,
  }) => CadSceneEntity(
    id: id,
    kind: CadSceneEntityKind.mesh,
    geometry: {
      'nodes': geometry.nodes,
      'triangles': geometry.triangles,
      'bounds': bounds.toJson(),
    },
  );
}
