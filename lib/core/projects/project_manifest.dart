class ProjectManifest {
  const ProjectManifest({
    required this.projectId,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.artifacts = const {},
  });
  static const schema = 'flcad.project';
  static const currentVersion = 1;
  final String projectId;
  final int schemaVersion;
  final DateTime createdAt, updatedAt;
  final Map<String, List<String>> artifacts;
  Map<String, dynamic> toJson() => {
    'schema': schema,
    'schemaVersion': schemaVersion,
    'projectId': projectId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'artifacts': artifacts,
  };
  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
      ProjectManifest(
        projectId: json['projectId'] as String,
        schemaVersion: json['schemaVersion'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        artifacts: ((json['artifacts'] as Map?) ?? const {}).map(
          (key, value) =>
              MapEntry(key as String, (value as List).cast<String>()),
        ),
      );
}
