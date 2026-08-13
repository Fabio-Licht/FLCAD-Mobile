import '../models/kernel_models.dart';

enum KernelExchangeFormat { step, iges, brep }

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
