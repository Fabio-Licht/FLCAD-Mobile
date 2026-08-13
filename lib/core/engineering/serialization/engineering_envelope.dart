class EngineeringEnvelope {
  const EngineeringEnvelope({
    required this.schema,
    required this.version,
    required this.projectId,
    required this.payload,
    required this.createdAt,
  });
  final String schema, projectId;
  final int version;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'projectId': projectId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'payload': payload,
  };
  factory EngineeringEnvelope.fromJson(Map<String, dynamic> j) =>
      EngineeringEnvelope(
        schema: j['schema'] as String,
        version: j['version'] as int,
        projectId: j['projectId'] as String,
        payload: (j['payload'] as Map).cast(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
