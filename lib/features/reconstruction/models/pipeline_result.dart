class PipelineResult {
  const PipelineResult({
    required this.success,
    required this.cancelled,
    required this.startedAt,
    required this.endedAt,
    required this.completedSteps,
    required this.resultPath,
    this.error,
  });
  final bool success;
  final bool cancelled;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<String> completedSteps;
  final String? resultPath;
  final String? error;

  Map<String, dynamic> toJson() => {
    'success': success,
    'cancelled': cancelled,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'completedSteps': completedSteps,
    'resultPath': resultPath,
    'error': error,
  };
  factory PipelineResult.fromJson(Map<String, dynamic> json) => PipelineResult(
    success: json['success'] as bool,
    cancelled: json['cancelled'] as bool,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
    completedSteps: (json['completedSteps'] as List).cast<String>(),
    resultPath: json['resultPath'] as String?,
    error: json['error'] as String?,
  );
}
