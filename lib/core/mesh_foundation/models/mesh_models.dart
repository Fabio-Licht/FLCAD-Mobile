import '../../cad_kernel/io/kernel_io_models.dart';

enum MeshState { open, closed, reloading, failed }

enum MeshHealth { healthy, warning, invalid }

class MeshEntity {
  MeshEntity({
    required this.id,
    required this.name,
    required this.sourceFile,
    required this.checksum,
    required this.fileSize,
    required this.kernelHandle,
    required this.units,
    required this.orientation,
    required this.importDate,
    required this.importTime,
    required this.kernelTime,
    required this.repositoryTime,
    required this.health,
    required this.validationStatus,
  });
  final String id, sourceFile, checksum, units, orientation, validationStatus;
  String name;
  final int fileSize;
  KernelMeshHandle kernelHandle;
  final DateTime importDate;
  final Duration importTime, kernelTime, repositoryTime;
  MeshState state = MeshState.open;
  MeshHealth health;
  int get triangleCount => kernelHandle.triangleCount;
  int get vertexCount => kernelHandle.vertexCount;
  KernelBounds get bounds => kernelHandle.bounds;
  bool get hasNormals => kernelHandle.hasNormals;
  int get degenerateTriangleCount => kernelHandle.degenerateTriangleCount;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceFile': sourceFile,
    'checksum': checksum,
    'fileSize': fileSize,
    'triangleCount': triangleCount,
    'vertexCount': vertexCount,
    'boundingBox': bounds.toJson(),
    'units': units,
    'normals': hasNormals,
    'degenerateTriangles': degenerateTriangleCount,
    'orientation': orientation,
    'importDate': importDate.toIso8601String(),
    'kernelHandle': kernelHandle.persistentId,
    'kernelId': kernelHandle.kernelId,
    'health': health.name,
    'validationStatus': validationStatus,
    'state': state.name,
    'importMicros': importTime.inMicroseconds,
    'kernelMicros': kernelTime.inMicroseconds,
    'repositoryMicros': repositoryTime.inMicroseconds,
  };
}

class MeshDiagnostic {
  const MeshDiagnostic(this.severity, this.code, this.message);
  final String severity, code, message;
  Map<String, dynamic> toJson() => {
    'severity': severity,
    'code': code,
    'message': message,
  };
}

class MeshImportResult {
  const MeshImportResult(this.mesh, this.diagnostics);
  final MeshEntity mesh;
  final List<MeshDiagnostic> diagnostics;
}
