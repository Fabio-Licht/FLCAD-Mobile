import '../models/mesh_models.dart';

class MeshDiagnostics {
  const MeshDiagnostics();
  Map<String, dynamic> report(MeshEntity mesh, List<MeshDiagnostic> issues) => {
    'mesh': mesh.id,
    'health': mesh.health.name,
    'warnings': issues
        .where((e) => e.severity == 'warning')
        .map((e) => e.toJson())
        .toList(),
    'errors': issues
        .where((e) => e.severity == 'error')
        .map((e) => e.toJson())
        .toList(),
    'importMicros': mesh.importTime.inMicroseconds,
    'kernelMicros': mesh.kernelTime.inMicroseconds,
    'repositoryMicros': mesh.repositoryTime.inMicroseconds,
    'memoryBytes': mesh.fileSize,
  };
}
