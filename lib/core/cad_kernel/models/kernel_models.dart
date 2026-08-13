enum KernelCapability {
  step,
  iges,
  brep,
  boolean,
  fillet,
  chamfer,
  loft,
  sweep,
  healing,
  meshing,
  gpu,
  extrude,
  revolve,
  offset,
  shell,
  draft,
  mirror,
  linearPattern,
  circularPattern,
}

enum CADShapeType { vertex, edge, wire, face, shell, solid, compound }

enum KernelHealthStatus { healthy, degraded, unavailable }

enum TransactionStatus { active, committed, rolledBack }

enum GeometryHistoryAction { create, modify, rollback, merge }

class KernelCapabilities {
  const KernelCapabilities(this.values);
  final Set<KernelCapability> values;
  bool supports(KernelCapability value) => values.contains(value);
  static const none = KernelCapabilities({});
}

class KernelDescriptor {
  const KernelDescriptor({
    required this.id,
    required this.name,
    required this.version,
    required this.capabilities,
    required this.vendor,
  });
  final String id, name, version, vendor;
  final KernelCapabilities capabilities;
}

class KernelHealth {
  const KernelHealth(this.status, this.message, this.checkedAt);
  final KernelHealthStatus status;
  final String message;
  final DateTime checkedAt;
}

class ShapeHandle {
  const ShapeHandle._(
    this.persistentId,
    this.kernelId,
    this.type,
    this.revision,
    this.fingerprint,
    this.metadata,
  );
  final String persistentId, kernelId;
  final CADShapeType type;
  final int revision;
  final String? fingerprint;
  final Map<String, dynamic> metadata;
  factory ShapeHandle.reference({
    required String persistentId,
    required String kernelId,
    required CADShapeType type,
    int revision = 1,
    String? fingerprint,
    Map<String, dynamic> metadata = const {},
  }) {
    if (persistentId.trim().isEmpty) {
      throw ArgumentError('Persistent ID required');
    }
    return ShapeHandle._(
      persistentId,
      kernelId,
      type,
      revision,
      fingerprint,
      Map.unmodifiable(metadata),
    );
  }
  Map<String, dynamic> toJson() => {
    'persistentId': persistentId,
    'kernelId': kernelId,
    'type': type.name,
    'revision': revision,
    if (fingerprint != null) 'fingerprint': fingerprint,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
  factory ShapeHandle.fromJson(Map<String, dynamic> j) => ShapeHandle.reference(
    persistentId: j['persistentId'] as String,
    kernelId: j['kernelId'] as String,
    type: CADShapeType.values.byName(j['type'] as String),
    revision: j['revision'] as int,
    fingerprint: j['fingerprint'] as String?,
    metadata: Map<String, dynamic>.from(
      j['metadata'] as Map? ?? const <String, dynamic>{},
    ),
  );
  @override
  bool operator ==(Object other) =>
      other is ShapeHandle &&
      other.persistentId == persistentId &&
      other.kernelId == kernelId &&
      other.revision == revision;
  @override
  int get hashCode => Object.hash(persistentId, kernelId, revision);
}

class KernelTransaction {
  const KernelTransaction(
    this.id,
    this.projectId,
    this.kernelId,
    this.startedAt,
    this.status,
    this.operationIds,
  );
  final String id, projectId, kernelId;
  final DateTime startedAt;
  final TransactionStatus status;
  final List<String> operationIds;
  KernelTransaction copyWith({
    TransactionStatus? status,
    List<String>? operationIds,
  }) => KernelTransaction(
    id,
    projectId,
    kernelId,
    startedAt,
    status ?? this.status,
    operationIds ?? this.operationIds,
  );
}

class GeometryHistoryRecord {
  const GeometryHistoryRecord(
    this.id,
    this.projectId,
    this.action,
    this.shapeIds,
    this.transactionId,
    this.timestamp,
    this.actor,
    this.metadata,
  );
  final String id, projectId, transactionId, actor;
  final GeometryHistoryAction action;
  final List<String> shapeIds;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

class KernelMetric {
  const KernelMetric(
    this.operation,
    this.elapsed,
    this.memoryDeltaBytes,
    this.entityCount,
    this.success,
    this.timestamp,
  );
  final String operation;
  final Duration elapsed;
  final int memoryDeltaBytes, entityCount;
  final bool success;
  final DateTime timestamp;
}
