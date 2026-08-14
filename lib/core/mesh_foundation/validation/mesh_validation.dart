import '../models/mesh_models.dart';

class MeshValidation {
  const MeshValidation();
  List<MeshDiagnostic> validate(MeshEntity mesh) => [
    if (mesh.fileSize == 0)
      const MeshDiagnostic('error', 'empty-file', 'STL file is empty'),
    if (mesh.triangleCount == 0)
      const MeshDiagnostic(
        'error',
        'empty-triangulation',
        'STL has no triangles',
      ),
    if (mesh.vertexCount == 0)
      const MeshDiagnostic('error', 'empty-vertices', 'STL has no vertices'),
    if (!mesh.hasNormals)
      const MeshDiagnostic(
        'warning',
        'missing-normals',
        'Triangulation has no stored normals',
      ),
    if (mesh.degenerateTriangleCount > 0)
      MeshDiagnostic(
        'warning',
        'degenerate-triangles',
        '${mesh.degenerateTriangleCount} degenerate triangles detected',
      ),
    if (mesh.bounds.minX > mesh.bounds.maxX ||
        mesh.bounds.minY > mesh.bounds.maxY ||
        mesh.bounds.minZ > mesh.bounds.maxZ)
      const MeshDiagnostic(
        'error',
        'invalid-bounds',
        'Bounding box is invalid',
      ),
    if (mesh.checksum.isEmpty)
      const MeshDiagnostic(
        'error',
        'missing-checksum',
        'Checksum was not generated',
      ),
  ];
}
