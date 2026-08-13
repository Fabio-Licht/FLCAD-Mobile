class SolidHandle {
  const SolidHandle(
    this.id,
    this.kernelId,
    this.nativeReference,
    this.fingerprint, {
    this.metadata = const {},
  });
  final String id, kernelId, nativeReference, fingerprint;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kernelId': kernelId,
    'nativeReference': nativeReference,
    'fingerprint': fingerprint,
    'metadata': metadata,
  };
  factory SolidHandle.fromJson(Map<String, dynamic> j) => SolidHandle(
    j['id'] as String,
    j['kernelId'] as String,
    j['nativeReference'] as String,
    j['fingerprint'] as String,
    metadata: (j['metadata'] as Map? ?? const {}).cast(),
  );
}

class EngineeringSolid {
  const EngineeringSolid({
    required this.id,
    required this.projectId,
    required this.name,
    required this.featureIds,
    required this.sourceIds,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.handle,
    this.metadata = const {},
  });
  final String id, projectId, name;
  final List<String> featureIds, sourceIds;
  final int version;
  final DateTime createdAt, updatedAt;
  final SolidHandle? handle;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'featureIds': featureIds,
    'sourceIds': sourceIds,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'handle': handle?.toJson(),
    'metadata': metadata,
  };
  factory EngineeringSolid.fromJson(Map<String, dynamic> j) => EngineeringSolid(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    name: j['name'] as String,
    featureIds: (j['featureIds'] as List).cast(),
    sourceIds: (j['sourceIds'] as List).cast(),
    version: j['version'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    handle: j['handle'] == null
        ? null
        : SolidHandle.fromJson((j['handle'] as Map).cast()),
    metadata: (j['metadata'] as Map? ?? const {}).cast(),
  );
}
