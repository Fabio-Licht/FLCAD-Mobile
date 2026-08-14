import '../models/kernel_models.dart';

enum KernelExchangeFormat { step, iges, brep }

enum KernelImportFormat { stl, asciiStl, binaryStl, autoDetect }

class KernelBounds {
  const KernelBounds(
    this.minX,
    this.minY,
    this.minZ,
    this.maxX,
    this.maxY,
    this.maxZ,
  );
  final double minX, minY, minZ, maxX, maxY, maxZ;
  Map<String, dynamic> toJson() => {
    'min': [minX, minY, minZ],
    'max': [maxX, maxY, maxZ],
  };
}

class KernelMeshHandle {
  const KernelMeshHandle({
    required this.persistentId,
    required this.kernelId,
    required this.fingerprint,
    required this.vertexCount,
    required this.triangleCount,
    required this.bounds,
    required this.hasNormals,
    required this.metadata,
    this.degenerateTriangleCount = 0,
  });
  final String persistentId, kernelId, fingerprint;
  final int vertexCount, triangleCount;
  final KernelBounds bounds;
  final bool hasNormals;
  final int degenerateTriangleCount;
  final Map<String, dynamic> metadata;
}

abstract interface class MeshGeometryKernelAPI {
  Future<KernelMeshHandle> importStl(
    String path, {
    required String projectId,
    KernelImportFormat format = KernelImportFormat.autoDetect,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  });
  Future<void> closeMesh(KernelMeshHandle handle);
}

class KernelProgress {
  const KernelProgress(this.operation, this.fraction, this.message);
  final String operation, message;
  final double fraction;
}

class GeometryDiagnostic {
  const GeometryDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    this.shapeId,
    this.metadata = const {},
  });
  final String code, message, severity;
  final String? shapeId;
  final Map<String, dynamic> metadata;
}

class HealingProposal {
  const HealingProposal({
    required this.id,
    required this.operation,
    required this.reason,
    required this.diagnostics,
    this.metadata = const {},
  });
  final String id, operation, reason;
  final List<GeometryDiagnostic> diagnostics;
  final Map<String, dynamic> metadata;
}

class KernelMeshResult {
  const KernelMeshResult({
    required this.source,
    required this.vertexCount,
    required this.triangleCount,
    required this.payloadPath,
  });
  final ShapeHandle source;
  final int vertexCount, triangleCount;
  final String payloadPath;
}

abstract interface class KernelCancellationToken {
  bool get isCancelled;
}

class NoKernelCancellation implements KernelCancellationToken {
  const NoKernelCancellation();
  @override
  bool get isCancelled => false;
}
