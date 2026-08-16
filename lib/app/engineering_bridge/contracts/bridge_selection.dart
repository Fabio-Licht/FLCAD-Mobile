import '../../../core/cad_kernel/io/kernel_io_models.dart';
import '../../../core/geometric_kernel/geometry/vectors.dart';

enum BridgeSelectionKind {
  triangle,
  patch,
  meshRegion,
  face,
  surface,
  cadEntity,
}

class BridgeSelection {
  const BridgeSelection({
    required this.id,
    required this.kind,
    required this.geometry,
    required this.triangleIndices,
    this.entityId,
  });
  final String id;
  final BridgeSelectionKind kind;
  final KernelMeshGeometry geometry;
  final Set<int> triangleIndices;
  final String? entityId;
}

class MeshRegion {
  const MeshRegion({
    required this.id,
    required this.meshId,
    required this.triangleIndices,
    required this.vertexIndices,
    required this.points,
    required this.normals,
    required this.bounds,
    required this.area,
    required this.connectivity,
    required this.fingerprint,
  });
  final String id, meshId, fingerprint;
  final List<int> triangleIndices, vertexIndices;
  final List<Vector3> points, normals;
  final KernelBounds bounds;
  final double area;
  final Map<int, Set<int>> connectivity;
}

class MeshRay {
  const MeshRay(this.origin, this.direction);
  final Vector3 origin, direction;
}

class MeshHit {
  const MeshHit({
    required this.triangleIndex,
    required this.point,
    required this.distance,
  });
  final int triangleIndex;
  final Vector3 point;
  final double distance;
}
