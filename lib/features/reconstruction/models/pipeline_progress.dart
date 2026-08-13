class PipelineProgress {
  const PipelineProgress({
    required this.stepId,
    required this.stepName,
    required this.stepIndex,
    required this.totalSteps,
    required this.fraction,
    this.fromCache = false,
  });

  final String stepId;
  final String stepName;
  final int stepIndex;
  final int totalSteps;
  final double fraction;
  final bool fromCache;

  int get percent => (fraction * 100).clamp(0, 100).round();

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'stepName': stepName,
    'stepIndex': stepIndex,
    'totalSteps': totalSteps,
    'fraction': fraction,
    'fromCache': fromCache,
  };
  factory PipelineProgress.fromJson(Map<String, dynamic> json) =>
      PipelineProgress(
        stepId: json['stepId'] as String,
        stepName: json['stepName'] as String,
        stepIndex: json['stepIndex'] as int,
        totalSteps: json['totalSteps'] as int,
        fraction: (json['fraction'] as num).toDouble(),
        fromCache: json['fromCache'] as bool? ?? false,
      );
}
