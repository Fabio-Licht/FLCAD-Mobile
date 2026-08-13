class PipelineContext {
  PipelineContext({
    required this.projectId,
    required this.projectPath,
    required this.imagePaths,
    required this.fingerprint,
    Map<String, dynamic>? values,
  }) : values = values ?? <String, dynamic>{};
  final String projectId;
  final String projectPath;
  final List<String> imagePaths;
  final String fingerprint;
  final Map<String, dynamic> values;

  String get reconstructionPath => '$projectPath/Reconstruction';
  String get cachePath => '$reconstructionPath/Cache';

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'projectPath': projectPath,
    'imagePaths': imagePaths,
    'fingerprint': fingerprint,
    'values': values,
  };
  factory PipelineContext.fromJson(Map<String, dynamic> json) =>
      PipelineContext(
        projectId: json['projectId'] as String,
        projectPath: json['projectPath'] as String,
        imagePaths: (json['imagePaths'] as List).cast<String>(),
        fingerprint: json['fingerprint'] as String,
        values: (json['values'] as Map?)?.cast<String, dynamic>(),
      );
}
